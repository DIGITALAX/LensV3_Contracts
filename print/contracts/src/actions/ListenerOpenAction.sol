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

contract ListenerOpenAction is IPostAction {
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

    event ListenerPurchased(
        address buyerAddress,
        uint256 collectionId,
        uint256 postId,
        uint256 totalAmount
    );
    event ListenerInitialized(
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
        (
            PrintLibrary.CollectionValuesParams memory _collectionCreator,
            uint256 _printType
        ) = abi.decode(_data, (PrintLibrary.CollectionValuesParams, uint256));

        if (!printAccessControl.isDesigner(originalMsgSender)) {
            revert PrintErrors.InvalidAddress();
        }

        uint256 _collectionId = _configureCollection(
            _collectionCreator,
            originalMsgSender,
            _printType,
            postId
        );

        _collectionGroups[postId] = _collectionId;

        emit ListenerInitialized(
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
        bytes memory _data = _getParamValue(params, "buyListener");
        (
            uint256[] memory _chosenIndexes,
            uint256[] memory _quantities,
            string memory _encryptedFulfillment,
            address _currency
        ) = abi.decode(_data, (uint256[], uint256[], string, address));

        if (!printSplitsData.getIsCurrency(_currency)) {
            revert PrintErrors.CurrencyNotWhitelisted();
        }

        uint256 _collectionId = _collectionGroups[postId];

        uint256 _grandTotal = _managePurchase(
            _chosenIndexes,
            _quantities,
            _collectionId,
            _currency,
            originalMsgSender
        );

        PrintLibrary.BuyTokensParams memory _buyTokensParams = PrintLibrary
            .BuyTokensParams({
                collectionIds: _fillCollection(
                    _collectionId,
                    _quantities.length
                ),
                collectionAmounts: _quantities,
                collectionIndexes: _chosenIndexes,
                details: _encryptedFulfillment,
                buyerAddress: originalMsgSender,
                chosenCurrency: _currency,
                postId: postId
            });

        marketCreator.buyTokens(_buyTokensParams);

        emit ListenerPurchased(
            originalMsgSender,
            _collectionId,
            postId,
            _grandTotal
        );

        return abi.encode(_collectionId, _currency, _chosenIndexes);
    }

    function _transferTokens(
        uint256 collectionId,
        uint256 chosenIndex,
        uint256 chosenAmount,
        address chosenCurrency,
        address designer,
        address buyer
    ) internal returns (uint256) {
        uint256 _totalPrice = printDesignData.getCollectionPrices(collectionId)[
            chosenIndex
        ] * chosenAmount;
        uint256 _calculatedPrice = _calculateAmount(
            chosenCurrency,
            _totalPrice
        );

        IERC20(chosenCurrency).transferFrom(buyer, designer, _calculatedPrice);

        return _calculatedPrice;
    }

    function setPrintDesignDataAddress(
        address newPrintDesignDataAddress
    ) public onlyAdmin {
        printDesignData = PrintDesignData(newPrintDesignDataAddress);
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function setPrintCommunityDataAddress(
        address newPrintCommunityDataAddress
    ) public onlyAdmin {
        printCommunityData = PrintCommunityData(newPrintCommunityDataAddress);
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
        uint256 printType,
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
                printType: printType,
                origin: 3,
                amount: creator.amount,
                unlimited: creator.unlimited,
                encrypted: creator.encrypted
            })
        );

        return _collectionId;
    }

    function _fillCollection(
        uint256 collectionId,
        uint256 quantitiesLength
    ) internal pure returns (uint256[] memory) {
        uint256[] memory collectionIds = new uint256[](quantitiesLength);
        for (uint256 i = 0; i < quantitiesLength; i++) {
            collectionIds[i] = collectionId;
        }
        return collectionIds;
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

    function _managePurchase(
        uint256[] memory chosenIndexes,
        uint256[] memory quantities,
        uint256 collectionId,
        address currency,
        address buyer
    ) internal returns (uint256) {
        uint256 _total = 0;

        for (uint256 i = 0; i < chosenIndexes.length; i++) {
            if (
                !printDesignData.getIsCollectionTokenAccepted(
                    collectionId,
                    currency
                )
            ) {
                revert PrintErrors.CurrencyNotWhitelisted();
            }

            if (!_checkCommunity(buyer, collectionId)) {
                revert PrintErrors.InvalidCommunityMember();
            }

            if (
                printDesignData.getCollectionTokensMinted(collectionId) +
                    quantities[i] >
                printDesignData.getCollectionAmount(collectionId)
            ) {
                revert PrintErrors.ExceedAmount();
            }

            _total = _transferTokens(
                collectionId,
                chosenIndexes[i],
                quantities[i],
                currency,
                printDesignData.getCollectionCreator(collectionId),
                buyer
            );
        }

        return _total;
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
