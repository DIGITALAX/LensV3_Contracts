// SPDX-License-Identifier: UNLICENSE

pragma solidity 0.8.24;

import "./PrintAccessControl.sol";
import "./PrintCommunityData.sol";
import "./PrintOrderData.sol";
import "./PrintErrors.sol";
import "./PrintDesignData.sol";

contract CommunityCreator {
    PrintAccessControl public printAccessControl;
    PrintCommunityData public printCommunityData;
    PrintDesignData public printDesignData;
    PrintOrderData public printOrderData;
    string public symbol;
    string public name;

    modifier onlyCommunitySteward() {
        if (!printAccessControl.isCommunitySteward(msg.sender)) {
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
        address printOrderDataAddress,
        address printAccessControlAddress,
        address printDesignDataAddress
    ) {
        printAccessControl = PrintAccessControl(printAccessControlAddress);
        printOrderData = PrintOrderData(printOrderDataAddress);
        printDesignData = PrintDesignData(printDesignDataAddress);

        symbol = "CCR";
        name = "CollectionCreator";
    }

    function createNewCommunity(
        PrintLibrary.CreateCommunityParams memory params
    ) public onlyCommunitySteward {
        printCommunityData.createCommunity(params);
    }

    function updateExistingCommunity(
        PrintLibrary.CreateCommunityParams memory params,
        uint256 communityId
    ) public {
        if (printCommunityData.getCommunitySteward(communityId) != msg.sender) {
            revert PrintErrors.InvalidAddress();
        }

        printCommunityData.updateCommunity(params, communityId);
    }

    function joinCommunity(address memberAddress, uint256 communityId) public {
        uint256[] memory _tokenIds = printOrderData.getAddressToTokenIds(
            memberAddress
        );

        bool _isValid = false;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            address _creator = printDesignData.getCollectionCreator(
                _tokenIds[i]
            );
            uint256 _origin = printDesignData.getCollectionOrigin(_tokenIds[i]);
            uint256 _print = printDesignData.getCollectionPrintType(
                _tokenIds[i]
            );

            if (
                printCommunityData.getCommunityIsValidCreator(
                    _creator,
                    communityId
                ) &&
                printCommunityData.getCommunityIsValidOrigin(
                    _origin,
                    communityId
                ) &&
                printCommunityData.getCommunityIsValidPrintType(
                    _print,
                    communityId
                )
            ) {
                _isValid = true;
                break;
            }
        }

        if (!_isValid) {
            revert PrintErrors.RequirementsNotMet();
        }

        address[] memory _valid20AddressKeys = printCommunityData
            .getCommunityValid20AddressKeys(communityId);

        _isValid = false;

        for (uint256 i = 0; i < _valid20AddressKeys.length; i++) {
            if (
                IERC20(_valid20AddressKeys[i]).balanceOf(memberAddress) >=
                printCommunityData.getCommunityValid20Threshold(
                    _valid20AddressKeys[i],
                    communityId
                )
            ) {
                _isValid = true;
                break;
            }
        }

        if (!_isValid) {
            revert PrintErrors.RequirementsNotMet();
        }

        printCommunityData.addCommunityMember(memberAddress, communityId);
    }

    function leaveCommunity(uint256 communityId) public {
        if (
            !printCommunityData.getIsValidCommunityAddress(
                msg.sender,
                communityId
            )
        ) {
            revert PrintErrors.InvalidAddress();
        }

        printCommunityData.removeCommunityMember(msg.sender, communityId);
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
}
