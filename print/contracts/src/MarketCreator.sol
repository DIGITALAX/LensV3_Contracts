// SPDX-License-Identifier: UNLICENSE

pragma solidity 0.8.24;

import "./PrintAccessControl.sol";
import "./PrintOrderData.sol";
import "./CollectionCreator.sol";
import "./PrintSplitsData.sol";
import "./PrintDesignData.sol";
import "./PrintErrors.sol";

contract MarketCreator {
    PrintAccessControl public printAccessControl;
    PrintOrderData public printOrderData;
    CollectionCreator public collectionCreator;
    PrintSplitsData public printSplitsData;
    PrintDesignData public printDesignData;
    string public symbol;
    string public name;

    modifier onlyAdmin() {
        if (!printAccessControl.isAdmin(msg.sender)) {
            revert PrintErrors.InvalidAddress();
        }
        _;
    }

    constructor(
        address printAccessControlAddress,
        address printSplitsDataAddress,
        address printOrderDataAddress,
        address collectionCreatorAddress,
        address printDesignDataAddress
    ) {
        printAccessControl = PrintAccessControl(printAccessControlAddress);
        printOrderData = PrintOrderData(printOrderDataAddress);
        collectionCreator = CollectionCreator(collectionCreatorAddress);
        printSplitsData = PrintSplitsData(printSplitsDataAddress);
        printDesignData = PrintDesignData(printDesignDataAddress);
        symbol = "MCR";
        name = "MarketCreator";
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function setPrintOrderDataAddress(
        address newPrintOrderDataAddress
    ) public onlyAdmin {
        printOrderData = PrintOrderData(newPrintOrderDataAddress);
    }

    function setPrintDesignDataAddress(
        address newPrintDesignDataAddress
    ) public onlyAdmin {
        printDesignData = PrintDesignData(newPrintDesignDataAddress);
    }

    function setCollectionCreatorAddress(
        address newCollectionCreatorAddress
    ) public onlyAdmin {
        collectionCreator = CollectionCreator(newCollectionCreatorAddress);
    }

    function setPrintSplitsDataAddress(
        address newPrintSplitsDataAddress
    ) public onlyAdmin {
        printSplitsData = PrintSplitsData(newPrintSplitsDataAddress);
    }

    function buyTokens(PrintLibrary.BuyTokensParams memory params) external {
        if (!printAccessControl.isOpenAction(msg.sender)) {
            revert PrintErrors.InvalidAddress();
        }

        uint256[] memory _prices = new uint256[](params.collectionIds.length);

        collectionCreator.purchaseAndMintToken(
            params.collectionIds,
            params.collectionAmounts,
            params.collectionIndexes,
            params.buyerAddress,
            params.chosenCurrency
        );

        for (uint256 i = 0; i < params.collectionIds.length; i++) {
            uint256[] memory _tokenIds = printDesignData.getCollectionTokenIds(
                params.collectionIds[i]
            );

            uint256[] memory _tokenIdsOrder = new uint256[](
                params.collectionAmounts[i]
            );
            for (uint256 j = 0; j < params.collectionAmounts[i]; j++) {
                _tokenIdsOrder[j] = _tokenIds[
                    _tokenIds.length - params.collectionAmounts[i] + j
                ];
            }

            uint256 _price = printDesignData.getCollectionPrices(
                params.collectionIds[i]
            )[params.collectionIndexes[i]] * params.collectionAmounts[i];

            address _fulfiller = printDesignData.getCollectionFulfiller(
                params.collectionIds[i]
            );

            printOrderData.createSubOrder(
                _tokenIdsOrder,
                _fulfiller,
                params.buyerAddress,
                params.collectionAmounts[i],
                printOrderData.getOrderSupply() + 1,
                _price,
                params.collectionIds[i]
            );

            _prices[i] = _price;
        }

        uint256 _totalPrice = 0;

        for (uint256 i = 0; i < _prices.length; i++) {
            _totalPrice += _prices[i];
        }

        uint256[] memory _subOrderIds = new uint256[](
            params.collectionIds.length
        );
        for (uint256 i = 0; i < params.collectionIds.length; i++) {
            _subOrderIds[i] = printOrderData.getSubOrderSupply() - i;
        }

        printOrderData.createOrder(
            _subOrderIds,
            params.details,
            params.chosenCurrency,
            params.buyerAddress,
            params.postId,
            _totalPrice
        );
    }

    function buyTokensOnlyNFT(
        PrintLibrary.BuyTokensOnlyNFTParams memory params
    ) external {
        if (!printAccessControl.isOpenAction(msg.sender)) {
            revert PrintErrors.InvalidAddress();
        }

        collectionCreator.purchaseAndMintToken(
            _oneItem(params.collectionId),
            _oneItem(params.quantity),
            new uint256[](1),
            params.buyerAddress,
            params.chosenCurrency
        );

        uint256 _price = printDesignData.getCollectionPrices(
            params.collectionId
        )[0] * params.quantity;

        uint256[] memory _tokenIds = printDesignData.getCollectionTokenIds(
            params.collectionId
        );

        uint256[] memory _tokenIdsOrder = new uint256[](params.quantity);
        for (uint256 j = 0; j < params.quantity; j++) {
            _tokenIdsOrder[j] = _tokenIds[
                _tokenIds.length - params.quantity + j
            ];
        }

        printOrderData.createNFTOnlyOrder(
            _tokenIdsOrder,
            params.chosenCurrency,
            params.buyerAddress,
            params.postId,
            _price,
            params.collectionId,
            params.quantity
        );
    }

    function _oneItem(uint256 value) private pure returns (uint256[] memory) {
        uint256[] memory _arr = new uint256[](1);
        _arr[0] = value;

        return _arr;
    }
}
