// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.24;

import "./AutographAccessControl.sol";
import "./AutographLibrary.sol";
import "./AutographCollections.sol";
import "./AutographMarket.sol";
import "./AutographErrors.sol";
import "./AutographCatalog.sol";

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

contract AutographAction is IPostAction {
    AutographAccessControl public autographAccessControl;
    AutographMarket public autographMarket;
    AutographCollections public autographCollections;
    AutographCatalog public autographCatalog;

    mapping(uint256 => uint256) _internalPostToCollection;

    modifier OnlyAdmin() {
        if (!autographAccessControl.isAdmin(msg.sender)) {
            revert AutographErrors.InvalidAddress();
        }
        _;
    }

    constructor(
        address _autographAccessControl,
        address _autographCollections,
        address _autographMarket,
        address _autographCatalog
    ) {
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
        autographMarket = AutographMarket(_autographMarket);
        autographCollections = AutographCollections(_autographCollections);
        autographCatalog = AutographCatalog(_autographCatalog);
    }

    function configure(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) external override returns (bytes memory) {
        bytes memory data = _getParamValue(params, "autographCreator");
        AutographLibrary.ActionParams memory _autographCreator = abi.decode(
            data,
            (AutographLibrary.ActionParams)
        );

        if (
            _autographCreator.autographType ==
            AutographLibrary.AutographType.Catalog &&
            autographAccessControl.isAdmin(originalMsgSender)
        ) {
            autographCatalog.createAutograph(
                AutographLibrary.AutographInit({
                    price: _autographCreator.price,
                    acceptedTokens: _autographCreator.acceptedTokens,
                    uri: _autographCreator.uri,
                    postId: postId,
                    amount: _autographCreator.amount,
                    pages: _autographCreator.pages,
                    designer: originalMsgSender,
                    pageCount: _autographCreator.pageCount
                })
            );
        } else {
            autographCollections.connectPublication(
                postId,
                _autographCreator.collectionId
            );
        }

        _internalPostToCollection[postId] = _autographCreator.collectionId;

        return
            abi.encode(
                _autographCreator.autographType,
                _autographCreator.amount,
                _autographCreator.uri,
                _autographCreator.price,
                _autographCreator.acceptedTokens
            );
    }

    function execute(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) external override returns (bytes memory) {
        string memory _encryptedFulfillment = abi.decode(
            _getParamValue(params, "encryptedFulfillment"),
            (string)
        );

        address _currency = abi.decode(
            _getParamValue(params, "currency"),
            (address)
        );

        uint8 _quantity = abi.decode(
            _getParamValue(params, "quantity"),
            (uint8)
        );

        uint256 _collectionId = 0;

        _collectionId = _internalPostToCollection[postId];

        autographMarket.buyTokenAction(
            _encryptedFulfillment,
            originalMsgSender,
            _currency,
            _collectionId,
            _quantity
        );

        return abi.encode(_collectionId, _currency);
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

    function setAutographAccessControl(
        address _autographAccessControl
    ) public OnlyAdmin {
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
    }

    function setAutographCatalog(address _autographCatalog) public OnlyAdmin {
        autographCatalog = AutographCatalog(_autographCatalog);
    }

    function setAutographCollections(
        address _autographCollections
    ) public OnlyAdmin {
        autographCollections = AutographCollections(_autographCollections);
    }

    function setAutographMarket(address _autographMarket) public OnlyAdmin {
        autographMarket = AutographMarket(_autographMarket);
    }
}
