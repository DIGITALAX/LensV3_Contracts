// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./CollectionCreator.sol";
import "./PrintAccessControl.sol";
import "./PrintLibrary.sol";
import "./PrintErrors.sol";


interface NFT {
    function mintBatch(
        address buyer,
        uint256 amount
    ) external returns (uint256[] memory);
}

contract NFTCreator {
    PrintAccessControl public printAccessControl;
    address public marketCreator;

    mapping(uint8 => address) private _nftOrigins;

    event BatchTokenMinted(uint256[] tokenIds, address to, uint8 origin);

    modifier onlyAdmin() {
        if (!printAccessControl.isAdmin(msg.sender)) {
            revert PrintErrors.AddressNotAdmin();
        }
        _;
    }

    constructor(address printAccessControlAddress) {
        printAccessControl = PrintAccessControl(printAccessControlAddress);
    }

    function mintTokens(
        address buyer,
        uint8 amount,
        uint8 origin
    ) public returns (uint256[] memory) {
        if (msg.sender != marketCreator) {
            revert PrintErrors.OnlyMarketCreator();
        }
        uint256[] memory _tokenIds = NFT(_nftOrigins[origin]).mintBatch(
            buyer,
            amount
        );

        emit BatchTokenMinted(_tokenIds, buyer, origin);

        return _tokenIds;
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function setMarketCreatorAddress(
        address marketCreatorAddress
    ) public onlyAdmin {
        marketCreator = marketCreatorAddress;
    }

    function setNFTOrigin(address nftAddress, uint8 origin) public onlyAdmin {
        _nftOrigins[origin] = nftAddress;
    }

    function getNFTOrigin(uint8 origin) public view returns (address) {
        return _nftOrigins[origin];
    }
}
