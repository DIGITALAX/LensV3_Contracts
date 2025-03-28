// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.24;

import "./AutographAccessControl.sol";
import "./AutographLibrary.sol";
import "./AutographCollections.sol";
import "./AutographMarket.sol";
import "./AutographErrors.sol";
import "./AutographCatalog.sol";

interface IPostAction {
    event Lens_PostAction_Configured(
        address indexed feed,
        uint256 indexed postId,
        bytes data
    );

    event Lens_PostAction_Executed(
        address indexed feed,
        uint256 indexed postId,
        bytes data
    );

    function configure(
        address feed,
        uint256 postId,
        bytes calldata data
    ) external returns (bytes memory);

    function execute(
        address feed,
        uint256 postId,
        bytes calldata data
    ) external returns (bytes memory);
}

contract AutographAction is IPostAction {
    AutographAccessControl public autographAccessControl;
    AutographMarket public autographMarket;
    AutographCollections public autographCollections;
    AutographCatalog public autographCatalog;
    string private _metadata;

    mapping(uint256 => mapping(uint256 => uint256)) _catalogGroups;

    modifier OnlyAdmin() {
        if (!autographAccessControl.isAdmin(msg.sender)) {
            revert AutographErrors.InvalidAddress();
        }
        _;
    }

    constructor(
        address _autographData,
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
        address feed,
        uint256 postId,
        bytes calldata data
    ) external override returns (bytes memory) {
        AutographLibrary.ActionParams memory _autographCreator = abi.decode(
            data,
            (AutographLibrary.ActionParams)
        );

        if (
            _autographCreator.autographType ==
            AutographLibrary.AutographType.Catalog &&
            autographAccessControl.isAdmin(msg.sender)
        ) {
            autographCatalog.createAutograph(
                AutographLibrary.AutographInit({
                    price: _autographCreator.price,
                    acceptedTokens: _autographCreator.acceptedTokens,
                    uri: _autographCreator.uri,
                    postId: postId,
                    amount: _autographCreator.amount,
                    pages: _autographCreator.pages,
                    designer: msg.sender,
                    pageCount: _autographCreator.pageCount
                })
            );
        } else {
            autographCollections.connectPublication(
                postId,
                _autographCreator.collectionId
            );
        }

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
        address feed,
        uint256 postId,
        bytes calldata data
    ) external override returns (bytes memory) {
        (
            string memory _encryptedFulfillment,
            address _currency,
            uint8 _quantity,
            AutographLibrary.AutographType _type
        ) = abi.decode(
                data,
                (string, address, uint8, AutographLibrary.AutographType)
            );

        uint256 _collectionId = 0;

        if (_type != AutographLibrary.AutographType.Catalog) {
            _collectionId = autographCollections.getCollectionByPostId(postId);
        }

        autographMarket.buyTokenAction(
            _encryptedFulfillment,
            msg.sender,
            _currency,
            _collectionId,
            _quantity,
            _type
        );

        return abi.encode(_type, _currency);
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
