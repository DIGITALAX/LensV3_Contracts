// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./AutographLibrary.sol";
import "./AutographCollections.sol";
import "./AutographMarket.sol";
import "./AutographErrors.sol";
import "./AutographCatalog.sol";

library Errors {
    error AccessDenied();
    error AllAnyOfRulesReverted();
    error AlreadyExists();
    error AlreadyInitialized();
    error AutoUpgradeEnabled();
    error Banned();
    error Blocked();
    error CannotFollowAgain();
    error CannotHaveRules();
    error CannotStartWithThat();
    error ConfigureCallReverted();
    error Disabled();
    error DoesNotExist();
    error DuplicatedValue();
    error Expired();
    error Immutable();
    error InvalidConfigSalt();
    error InvalidMsgSender();
    error InvalidParameter();
    error InvalidSignature();
    error LimitReached();
    error Locked();
    error NonceUsed();
    error NotAContract();
    error NotAllowed();
    error NotAMember();
    error NotEnough();
    error NotFollowing();
    error NotFound();
    error NotImplemented();
    error RedundantStateChange();
    error RequiredRuleReverted();
    error RuleNotConfigured();
    error SelectorEnabledForDifferentRuleType();
    error ActionOnSelf();
    error SingleAnyOfRule();
    error UnexpectedContractImpl();
    error UnexpectedValue();
    error UnsupportedSelector();
    error Untrusted();
    error UsernameAssigned();
    error WrongSigner();
}

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

contract AutographAction is BasePostAction {
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
        address actionHub,
        address _autographAccessControl,
        address _autographCollections,
        address _autographMarket,
        address _autographCatalog
    ) BasePostAction(actionHub) {
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
        autographMarket = AutographMarket(_autographMarket);
        autographCollections = AutographCollections(_autographCollections);
        autographCatalog = AutographCatalog(_autographCatalog);
    }

    function _configure(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) internal override returns (bytes memory) {
        bytes memory data = _getParamValue(
            params,
            "lens.param.autographCreator"
        );
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

    function _execute(
        address originalMsgSender,
        address feed,
        uint256 postId,
        KeyValue[] calldata params
    ) internal override returns (bytes memory) {
        string memory _encryptedFulfillment = abi.decode(
            _getParamValue(params, "lens.param.encryptedFulfillment"),
            (string)
        );

        address _currency = abi.decode(
            _getParamValue(params, "lens.param.currency"),
            (address)
        );


        uint8 _quantity = abi.decode(
            _getParamValue(params, "lens.param.quantity"),
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

        revert AutographErrors.KeyNotFound();
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
