// SPDX-License-Identifier: UNLICENSE

pragma solidity 0.8.24;

import "./PrintAccessControl.sol";
import "./PrintLibrary.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PrintErrors.sol";

contract PrintCommunityData {
    PrintAccessControl public printAccessControl;
    string public symbol;
    string public name;
    address public communityCreator;
    uint256 private _communitySupply;

    using SafeMath for uint256;

    mapping(uint256 => PrintLibrary.Community) private _communities;
    mapping(uint256 => uint256) public _memberToIndex;
    mapping(address => mapping(uint256 => bool)) private _addressToCommunity;

    event CommunityCreated(
        uint256 indexed communityId,
        address steward,
        string uri
    );
    event CommunityUpdated(
        uint256 indexed communityId,
        address steward,
        string uri
    );
    event CommunityMemberAdded(
        uint256 indexed communityId,
        address memberAddress
    );
    event CommunityMemberRemoved(uint256 indexed communityId);

    modifier onlyCommunityCreator() {
        if (msg.sender != communityCreator) {
            revert PrintErrors.InvalidAddress();
        }
        _;
    }
    modifier onlyAdmin() {
        if (!printAccessControl.isAdmin(msg.sender)) {
            revert PrintErrors.InvalidAddress();
        }
        _;
    }

    constructor(
        address printAccessControlAddress,
        address communityCreatorAddress
    ) {
        symbol = "PCD";
        name = "PrintCommunityData";
        printAccessControl = PrintAccessControl(printAccessControlAddress);
        communityCreator = communityCreatorAddress;
    }

    function createCommunity(
        PrintLibrary.CreateCommunityParams memory params
    ) external {
        _communitySupply++;

        _communities[_communitySupply].communityId = _communitySupply;
        _communities[_communitySupply].uri = params.uri;
        _communities[_communitySupply].steward = params.steward;

        for (uint256 i = 0; i < params.validCreators.length; i++) {
            _communities[_communitySupply].validCreators[
                params.validCreators[i]
            ] = true;

            _communities[_communitySupply].validCreatorKeys.push(
                params.validCreators[i]
            );
        }

        for (uint256 i = 0; i < params.validOrigins.length; i++) {
            _communities[_communitySupply].validOrigins[
                params.validOrigins[i]
            ] = true;

            _communities[_communitySupply].validOriginKeys.push(
                params.validOrigins[i]
            );
        }

        for (uint256 i = 0; i < params.validPrintTypes.length; i++) {
            _communities[_communitySupply].validPrintTypes[
                params.validPrintTypes[i]
            ] = true;

            _communities[_communitySupply].validPrintTypeKeys.push(
                params.validPrintTypes[i]
            );
        }

        for (uint256 i = 0; i < params.valid20Addresses.length; i++) {
            _communities[_communitySupply].valid20Thresholds[
                params.valid20Addresses[i]
            ] = params.valid20Thresholds[i];
            _communities[_communitySupply].valid20AddressKeys.push(
                params.valid20Addresses[i]
            );
        }

        emit CommunityCreated(_communitySupply, params.steward, params.uri);
    }

    function updateCommunity(
        PrintLibrary.CreateCommunityParams memory params,
        uint256 communityId
    ) external onlyCommunityCreator {
        PrintLibrary.Community storage _community = _communities[communityId];

        _community.uri = params.uri;
        _community.steward = params.steward;

        for (uint256 i = 0; i < _community.validCreatorKeys.length; i++) {
            delete _community.validCreators[_community.validCreatorKeys[i]];
        }
        for (uint256 i = 0; i < _community.validOriginKeys.length; i++) {
            delete _community.validOrigins[_community.validOriginKeys[i]];
        }
        for (uint256 i = 0; i < _community.validPrintTypeKeys.length; i++) {
            delete _community.validPrintTypes[_community.validPrintTypeKeys[i]];
        }

        for (uint256 i = 0; i < _community.valid20AddressKeys.length; i++) {
            delete _community.valid20Thresholds[
                _community.valid20AddressKeys[i]
            ];
        }

        delete _community.validCreatorKeys;
        delete _community.validOriginKeys;
        delete _community.validPrintTypeKeys;
        delete _community.valid20AddressKeys;

        for (uint256 i = 0; i < params.validCreators.length; i++) {
            _community.validCreators[params.validCreators[i]] = true;

            _community.validCreatorKeys.push(params.validCreators[i]);
        }

        for (uint256 i = 0; i < params.validOrigins.length; i++) {
            _community.validOrigins[params.validOrigins[i]] = true;

            _community.validOriginKeys.push(params.validOrigins[i]);
        }

        for (uint256 i = 0; i < params.validPrintTypes.length; i++) {
            _community.validPrintTypes[params.validPrintTypes[i]] = true;

            _community.validPrintTypeKeys.push(params.validPrintTypes[i]);
        }

        for (uint256 i = 0; i < params.valid20Addresses.length; i++) {
            _community.valid20Thresholds[params.valid20Addresses[i]] = params
                .valid20Thresholds[i];
            _community.valid20AddressKeys.push(params.valid20Addresses[i]);
        }

        emit CommunityUpdated(communityId, params.steward, params.uri);
    }

    function addCommunityMember(
        address memberAddress,
        uint256 communityId
    ) external onlyCommunityCreator {
        PrintLibrary.CommunityMember memory newMember = PrintLibrary
            .CommunityMember({memberAddress: memberAddress});
        _communities[communityId].communityMembers.push(newMember);
        _addressToCommunity[memberAddress][communityId] = true;
        _memberToIndex[communityId] =
            _communities[communityId].communityMembers.length -
            1;

        emit CommunityMemberAdded(communityId, memberAddress);
    }

    function removeCommunityMember(
        address memberAddress,
        uint256 communityId
    ) external onlyCommunityCreator {
        PrintLibrary.Community storage _community = _communities[communityId];

        uint256 _index = _memberToIndex[communityId];
        uint256 _lastIndex = _community.communityMembers.length.sub(1);

        PrintLibrary.CommunityMember memory _lastMember = _community
            .communityMembers[_lastIndex];

        _community.communityMembers[_index].memberAddress = _lastMember
            .memberAddress;

        _memberToIndex[communityId] = _index;
        _community.communityMembers.pop();

        delete _memberToIndex[communityId];

        _addressToCommunity[memberAddress][communityId] = false;

        emit CommunityMemberRemoved(communityId);
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function setCommunityCreatorAddress(
        address newCommunityCreatorAddress
    ) public onlyAdmin {
        communityCreator = newCommunityCreatorAddress;
    }

    function getCommunitySupply() public view returns (uint256) {
        return _communitySupply;
    }

    function getCommunitySteward(
        uint256 communityId
    ) public view returns (address) {
        return _communities[communityId].steward;
    }

    function getCommunityURI(
        uint256 communityId
    ) public view returns (string memory) {
        return _communities[communityId].uri;
    }

    function getCommunityMembers(
        uint256 communityId
    ) public view returns (PrintLibrary.CommunityMember[] memory) {
        return _communities[communityId].communityMembers;
    }

    function getCommunityValidOriginKeys(
        uint256 communityId
    ) public view returns (uint256[] memory) {
        return _communities[communityId].validOriginKeys;
    }

    function getCommunityValidCreatorKeys(
        uint256 communityId
    ) public view returns (address[] memory) {
        return _communities[communityId].validCreatorKeys;
    }

    function getCommunityValidPrintTypeKeys(
        uint256 communityId
    ) public view returns (uint256[] memory) {
        return _communities[communityId].validPrintTypeKeys;
    }

    function getCommunityValid20AddressKeys(
        uint256 communityId
    ) public view returns (address[] memory) {
        return _communities[communityId].valid20AddressKeys;
    }

    function getCommunityIsValidCreator(
        address creator,
        uint256 communityId
    ) public view returns (bool) {
        return _communities[communityId].validCreators[creator];
    }

    function getCommunityIsValidOrigin(
        uint256 origin,
        uint256 communityId
    ) public view returns (bool) {
        return _communities[communityId].validOrigins[origin];
    }

    function getCommunityIsValidPrintType(
        uint256 printType,
        uint256 communityId
    ) public view returns (bool) {
        return _communities[communityId].validPrintTypes[printType];
    }

    function getCommunityValid20Threshold(
        address tokenAddress,
        uint256 communityId
    ) public view returns (uint256) {
        return _communities[communityId].valid20Thresholds[tokenAddress];
    }

    function getIsValidCommunityAddress(
        address memberAddress,
        uint256 communityId
    ) public view returns (bool) {
        return _addressToCommunity[memberAddress][communityId];
    }

    function getMemberToIndex(
        uint256 communityId
    ) public view returns (uint256) {
        return _memberToIndex[communityId];
    }
}
