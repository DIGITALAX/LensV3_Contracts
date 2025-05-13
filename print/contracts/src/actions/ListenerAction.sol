// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./../MarketCreator.sol";
import "./../CollectionCreator.sol";
import "./../PrintAccessControl.sol";
import "./../PrintErrors.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../Lens/Ownable.sol";

bytes32 constant UNIVERSAL_ACTION_MAGIC_VALUE = 0xa12c06eea999f2a08fb2bd50e396b2a286921eebbda81fb45a0adcf13afb18ef;

interface IPostAction {
    function configure(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) external returns (bytes memory);

    function execute(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) external returns (bytes memory);

    function setDisabled(
        address originalMsgSender,
        address feed,
        uint256 postId,
        bool isDisabled,
        KeyValue[] calldata params
    ) external returns (bytes memory);
}

abstract contract BaseAction {
    address immutable ACTION_HUB;

    /// @custom:keccak lens.storage.Action.configured
    bytes32 constant STORAGE__ACTION_CONFIGURED =
        0x852bead036b7ef35b8026346140cc688bafe817a6c3491812e6d994b1bcda6d9;

    modifier onlyActionHub() {
        require(msg.sender == ACTION_HUB, Errors.InvalidMsgSender());
        _;
    }

    constructor(address actionHub) {
        ACTION_HUB = actionHub;
    }

    function _configureUniversalAction(
        address originalMsgSender
    ) internal onlyActionHub returns (bytes memory) {
        bool configured;
        assembly {
            configured := sload(STORAGE__ACTION_CONFIGURED)
        }
        require(!configured, Errors.RedundantStateChange());
        require(originalMsgSender == address(0), Errors.InvalidParameter());
        assembly {
            sstore(STORAGE__ACTION_CONFIGURED, 1)
        }
        return abi.encode(UNIVERSAL_ACTION_MAGIC_VALUE);
    }
}

abstract contract BasePostAction is BaseAction, IPostAction {
    constructor(address actionHub) BaseAction(actionHub) {}

    function configure(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) external override onlyActionHub returns (bytes memory) {
        return _configure(originalMsgSender, feed, postId, params);
    }

    function execute(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) external override onlyActionHub returns (bytes memory) {
        return _execute(originalMsgSender, feed, postId, params);
    }

    function setDisabled(
        address originalMsgSender,
        address feed,
        uint256 postId,
        bool isDisabled,
        KeyValue[] calldata params
    ) external override onlyActionHub returns (bytes memory) {
        return
            _setDisabled(originalMsgSender, feed, postId, isDisabled, params);
    }

    function _configure(
        address originalMsgSender,
        address /* feed */,
        uint256 /* postId */,
        KeyValue[] calldata /* params */
    ) internal virtual returns (bytes memory) {
        return _configureUniversalAction(originalMsgSender);
    }

    function _execute(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) internal virtual returns (bytes memory);

    function _setDisabled(
        address /* originalMsgSender */,
        address /* feed */,
        uint256 /* postId */,
        bool /* isDisabled */,
        KeyValue[] calldata /* params */
    ) internal virtual returns (bytes memory) {
        revert Errors.NotImplemented();
    }
}

struct KeyValue {
    bytes32 key;
    bytes value;
}

contract ListenerAction is BasePostAction {
    MarketCreator public marketCreator;
    CollectionCreator public collectionCreator;
    PrintAccessControl public printAccessControl;
    PrintSplitsData public printSplitsData;

    mapping(uint256 => uint256) _collectionGroups;

    modifier onlyAdmin() {
        if (!printAccessControl.isAdmin(msg.sender)) {
            revert PrintErrors.InvalidAddress();
        }
        _;
    }

    event ListenerPurchased(
        uint256[] collectionIds,
        address buyer,
        uint256 postId,
        uint256 totalAmount
    );
    event ListenerInitialized(
        address designer,
        uint256 collectionId,
        uint256 postId
    );

    constructor(
        address actionHub,
        address printAccessControlAddress,
        address printSplitsDataAddress,
        address marketCreatorAddress,
        address collectionCreatorAddress
    ) BasePostAction(actionHub) {
        marketCreator = MarketCreator(marketCreatorAddress);
        collectionCreator = CollectionCreator(collectionCreatorAddress);
        printAccessControl = PrintAccessControl(printAccessControlAddress);
        printSplitsData = PrintSplitsData(printSplitsDataAddress);
    }

    function _configure(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) internal override returns (bytes memory) {
        address _designer = Ownable(originalMsgSender).owner();

        if (!printAccessControl.isDesigner(_designer)) {
            revert PrintErrors.InvalidAddress();
        }

        bytes memory _data = _getParamValue(
            params,
            "lens.param.collectionCreator"
        );
        PrintLibrary.CollectionInitParams memory _collectionCreator = abi
            .decode(_data, (PrintLibrary.CollectionInitParams));

        if (_collectionCreator.printType == 6) {
            revert PrintErrors.InvalidPrintType();
        }

        uint256 _collectionId = collectionCreator.createCollection(
            _collectionCreator,
            _designer,
            postId,
            2
        );

        _collectionGroups[postId] = _collectionId;

        emit ListenerInitialized(_designer, _collectionId, postId);
    }

    function _execute(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) internal override returns (bytes memory) {
        bytes memory _data = _getParamValue(params, "lens.param.buyListener");
        (
            string[] memory _details,
            address[] memory _currencies,
            uint256[] memory _collectionIds,
            uint8[] memory _amounts
        ) = abi.decode(_data, (string[], address[], uint256[], uint8[]));
        address _buyer = Ownable(originalMsgSender).owner();

        if (_collectionIds.length == 0) {
            _collectionIds = new uint256[](1);
            _collectionIds[0] = _collectionGroups[postId];
            _details = new string[](1);
            _details[0] = "";
        }

        for (uint8 i = 0; i < _collectionIds.length; i++) {
            _collectionCheck(_currencies[i], _collectionIds[i], _amounts[i]);
        }
        uint256 _total = 0;
        uint8[] memory _origins = new uint8[](_collectionIds.length);

        for (uint8 i = 0; i < _collectionIds.length; i++) {
            _total += _transferTokens(
                _currencies[i],
                _buyer,
                _collectionIds[i],
                _amounts[i]
            );

            _origins[i] = collectionCreator.getCollectionOrigin(
                _collectionIds[i]
            );
        }

        marketCreator.buyTokens(
            PrintLibrary.BuyParms({
                details: _details,
                currencies: _currencies,
                collectionIds: _collectionIds,
                origins: _origins,
                amounts: _amounts,
                buyer: _buyer
            })
        );

        emit ListenerPurchased(_collectionIds, _buyer, postId, _total);
    }

    function _collectionCheck(
        address currency,
        uint256 collectionId,
        uint8 amount
    ) internal view {
        if (!collectionCreator.getIsAcceptedToken(currency, collectionId)) {
            revert PrintErrors.CurrencyNotWhitelisted();
        }

        if (collectionCreator.getCollectionFrozen(collectionId)) {
            revert PrintErrors.CollectionFrozen();
        }

        if (
            collectionCreator.getCollectionMintedTokenIds(collectionId).length +
                amount >
            collectionCreator.getCollectionAmount(collectionId)
        ) {
            revert PrintErrors.ExceedAmount();
        }
    }

    function _transferTokens(
        address currency,
        address buyer,
        uint256 collectionId,
        uint256 amount
    ) internal returns (uint256) {
        address _designer = collectionCreator.getCollectionDesigner(
            collectionId
        );

        address _fulfiller = collectionCreator.getCollectionFulfiller(
            collectionId
        );
        uint8 _printType = collectionCreator.getCollectionPrintType(
            collectionId
        );

        uint256 _fulfillerBase = printSplitsData.getFulfillerBase(
            currency,
            _printType
        );
        uint256 _fulfillerSplit = printSplitsData.getFulfillerSplit(
            currency,
            _printType
        );

        uint256 _totalPrice = collectionCreator.getCollectionPrice(
            collectionId
        ) * amount;

        uint256 _calculatedPrice = _calculateAmount(currency, _totalPrice);
        uint256 _fulfillerAmount = 0;
        if (_fulfillerBase != 0) {
            uint256 _calculatedBase = _calculateAmount(
                currency,
                _fulfillerBase * amount
            );

            _fulfillerAmount =
                _calculatedBase +
                ((_fulfillerSplit * _calculatedPrice) / 1e20);

            if (_fulfillerAmount > 0) {
                IERC20(currency).transferFrom(
                    buyer,
                    _fulfiller,
                    _fulfillerAmount
                );
            }
        }

        if ((_calculatedPrice - _fulfillerAmount) > 0) {
            IERC20(currency).transferFrom(
                buyer,
                _designer,
                _calculatedPrice - _fulfillerAmount
            );
        }

        return _calculatedPrice;
    }

    function setPrintAccessControl(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function setPrintSplitsData(
        address newPrintSplitsDataAddress
    ) public onlyAdmin {
        printSplitsData = PrintSplitsData(newPrintSplitsDataAddress);
    }

    function setMarketCreator(
        address newMarketCreatorAddress
    ) public onlyAdmin {
        marketCreator = MarketCreator(newMarketCreatorAddress);
    }

    function setCollectionCreator(
        address newCollectionCreatorAddress
    ) public onlyAdmin {
        collectionCreator = CollectionCreator(newCollectionCreatorAddress);
    }

    function _calculateAmount(
        address currency,
        uint256 amountInWei
    ) internal view returns (uint256) {
        if (amountInWei == 0) {
            revert PrintErrors.InvalidAmounts();
        }

        uint256 _exchangeRate = printSplitsData.getCurrencyRate(currency);
        uint256 _weiDivisor = printSplitsData.getCurrencyWei(currency);
        uint256 _tokenAmount = (amountInWei * _weiDivisor) / _exchangeRate;

        return _tokenAmount;
    }

    function _setDisabled(
        address /* originalMsgSender */,
        address /* feed */,
        uint256 /* postId */,
        bool /* isDisabled */,
        KeyValue[] calldata /* params */
    ) internal override returns (bytes memory) {
        revert Errors.NotImplemented();
    }

    function _getParamValue(
        KeyValue[] calldata params,
        string memory keyLabel
    ) internal pure returns (bytes memory) {
        bytes32 lookupKey = keccak256(abi.encodePacked(keyLabel));
        for (uint256 i = 0; i < params.length; i++) {
            if (params[i].key == lookupKey) {
                return params[i].value;
            }
        }

        revert PrintErrors.KeyNotFound();
    }
}
