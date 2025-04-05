// SPDX-License-Identifier: UNLICENSE

pragma solidity 0.8.24;

import "./../MarketCreator.sol";
import "./../CollectionCreator.sol";
import "./../PrintAccessControl.sol";
import "./../PrintDesignData.sol";
import "./../PrintCommunityData.sol";
import "./../PrintErrors.sol";

struct KeyValue {
    bytes32 key;
    bytes value;
}

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

library ChromadinOpenActionLibrary {
    struct CollectionValues {
        uint256[][] prices;
        string[] uris;
        address[] fulfillers;
        uint256[] amounts;
        bool[] unlimiteds;
    }
}

contract ChromadinOpenAction is IPostAction {
    MarketCreator public marketCreator;
    CollectionCreator public collectionCreator;
    PrintAccessControl public printAccessControl;
    PrintSplitsData public printSplitsData;
    PrintDesignData public printDesignData;
    PrintCommunityData public printCommunityData;

    mapping(uint256 => uint256) _collectionGroups;

    modifier onlyAdmin() {
        if (!printAccessControl.isAdmin(msg.sender)) {
            revert PrintErrors.InvalidAddress();
        }
        _;
    }

    event ChromadinPurchased(
        address buyerAddress,
        uint256 collectionId,
        uint256 postId,
        uint256 totalAmount
    );
    event ChromadinInitialized(
        address creatorAddress,
        uint256 collectionId,
        uint256 postId,
        uint256 numberOfCollections
    );

    constructor(
        address printAccessControlAddress,
        address printSplitsDataAddress,
        address printDesignDataAddress,
        address marketCreatorAddress,
        address collectionCreatorAddress,
        address printCommunityDataAddress
    ) {
        marketCreator = MarketCreator(marketCreatorAddress);
        collectionCreator = CollectionCreator(collectionCreatorAddress);
        printAccessControl = PrintAccessControl(printAccessControlAddress);
        printSplitsData = PrintSplitsData(printSplitsDataAddress);
        printDesignData = PrintDesignData(printDesignDataAddress);
        printCommunityData = PrintCommunityData(printCommunityDataAddress);
    }

    function configure(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) external override returns (bytes memory) {
        bytes memory _data = _getParamValue(params, "collectionCreator");
        PrintLibrary.CollectionValuesParams memory _collectionCreator = abi
            .decode(_data, (PrintLibrary.CollectionValuesParams));

        if (!printAccessControl.isDesigner(originalMsgSender)) {
            revert PrintErrors.InvalidAddress();
        }

        uint256 _collectionId = _configureCollection(
            _collectionCreator,
            originalMsgSender,
            postId
        );

        _collectionGroups[postId] = _collectionId;

        emit ChromadinInitialized(
            originalMsgSender,
            _collectionId,
            postId,
            _collectionCreator.prices.length
        );

        return
            abi.encode(
                _collectionCreator.prices,
                _collectionCreator.acceptedTokens,
                _collectionCreator.uri
            );
    }

    function execute(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) external override returns (bytes memory) {
        bytes memory _data = _getParamValue(params, "buyChromadin");
        (address _currency, uint256 _quantity) = abi.decode(
            _data,
            (address, uint256)
        );

        if (!printSplitsData.getIsCurrency(_currency)) {
            revert PrintErrors.CurrencyNotWhitelisted();
        }

        uint256 _collectionId = _collectionGroups[postId];

        if (
            !printDesignData.getIsCollectionTokenAccepted(
                _collectionId,
                _currency
            )
        ) {
            revert PrintErrors.CurrencyNotWhitelisted();
        }

        if (!_checkCommunity(originalMsgSender, _collectionId)) {
            revert PrintErrors.InvalidCommunityMember();
        }

        if (
            printDesignData.getCollectionTokensMinted(_collectionId) +
                _quantity >
            printDesignData.getCollectionAmount(_collectionId)
        ) {
            revert PrintErrors.ExceedAmount();
        }

        address _designer = printDesignData.getCollectionCreator(_collectionId);

        uint256 _grandTotal = _transferTokens(
            _currency,
            _designer,
            originalMsgSender,
            _collectionId,
            _quantity
        );
        PrintLibrary.BuyTokensOnlyNFTParams
            memory _buyTokensParams = PrintLibrary.BuyTokensOnlyNFTParams({
                collectionId: _collectionId,
                quantity: _quantity,
                buyerAddress: originalMsgSender,
                chosenCurrency: _currency,
                postId: postId
            });

        marketCreator.buyTokensOnlyNFT(_buyTokensParams);

        emit ChromadinPurchased(
            originalMsgSender,
            _collectionId,
            postId,
            _grandTotal
        );

        return abi.encode(_collectionId, _currency);
    }

    function _transferTokens(
        address chosenCurrency,
        address designer,
        address buyer,
        uint256 collectionId,
        uint256 quantity
    ) internal returns (uint256) {
        uint256 _totalPrice = printDesignData.getCollectionPrices(collectionId)[
            0
        ];

        uint256 _calculatedPrice = _calculateAmount(
            chosenCurrency,
            _totalPrice * quantity
        );

        IERC20(chosenCurrency).transferFrom(buyer, designer, _calculatedPrice);

        return _calculatedPrice;
    }

    function setPrintDesignDataAddress(
        address newPrintDesignDataAddress
    ) public onlyAdmin {
        printDesignData = PrintDesignData(newPrintDesignDataAddress);
    }

    function setPrintCommunityDataAddress(
        address newPrintCommunityDataAddress
    ) public onlyAdmin {
        printCommunityData = PrintCommunityData(newPrintCommunityDataAddress);
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function setMarketCreatorAddress(
        address newMarketCreatorAddress
    ) public onlyAdmin {
        marketCreator = MarketCreator(newMarketCreatorAddress);
    }

    function setCollectionCreatorAddress(
        address newCollectionCreatorAddress
    ) public onlyAdmin {
        collectionCreator = CollectionCreator(newCollectionCreatorAddress);
    }

    function _configureCollection(
        PrintLibrary.CollectionValuesParams memory creator,
        address executor,
        uint256 postId
    ) internal returns (uint256) {
        uint256 _collectionId = collectionCreator.createCollection(
            PrintLibrary.MintParams({
                prices: creator.prices,
                acceptedTokens: creator.acceptedTokens,
                communityIds: creator.communityIds,
                uri: creator.uri,
                fulfiller: creator.fulfiller,
                postId: postId,
                dropId: creator.dropId,
                creator: executor,
                printType: 6,
                origin: 1,
                amount: creator.amount,
                unlimited: creator.unlimited,
                encrypted: creator.encrypted
            })
        );

        return _collectionId;
    }

    function _checkCommunity(
        address memberAddress,
        uint256 collectionId
    ) internal view returns (bool) {
        uint256[] memory _communityIds = printDesignData
            .getCollectionCommunityIds(collectionId);
        bool _validMember = true;

        if (_communityIds.length > 0) {
            _validMember = false;
            for (uint256 j = 0; j < _communityIds.length; j++) {
                if (
                    printCommunityData.getIsValidCommunityAddress(
                        memberAddress,
                        _communityIds[j]
                    )
                ) {
                    return _validMember = true;
                }
            }
        }

        return _validMember;
    }

    function _calculateAmount(
        address currency,
        uint256 amountInWei
    ) internal view returns (uint256) {
        if (amountInWei == 0) {
            revert PrintErrors.InvalidAmounts();
        }

        uint256 _exchangeRate = printSplitsData.getRateByCurrency(currency);

        uint256 _weiDivisor = printSplitsData.getWeiByCurrency(currency);
        uint256 _tokenAmount = (amountInWei * _weiDivisor) / _exchangeRate;

        return _tokenAmount;
    }

    function setDisabled(
        address originalMsgSender,
        address feed,
        uint256 postId,
        bool isDisabled,
        KeyValue[] calldata params
    ) external override returns (bytes memory) {
        return "";
    }

    function _getParamValue(
        KeyValue[] calldata params,
        string memory keyLabel
    ) internal pure returns (bytes memory) {
        bytes32 lookupKey = bytes32(abi.encodePacked(keyLabel));
        for (uint256 i = 0; i < params.length; i++) {
            if (params[i].key == lookupKey) {
                return params[i].value;
            }
        }
        revert("Key not found");
    }
}
