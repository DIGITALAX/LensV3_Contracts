// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

contract PrintErrors {
    error AddressNotMarket();
    error AddressNotDesigner();
    error AddressNotAdmin();
    error InvalidUpdate();
    error InvalidCurrency();
    error InvalidRemoval();

    error InvalidAddress();
    error InvalidDrop();
    error CollectionFrozen();

    error RequirementsNotMet();

    error OnlyMarketCreator();

    error AddressInvalid();
    error Existing();
    error CantRemoveSelf();

    error InvalidFulfiller();

    error ExistingCurrency();
    error CurrencyDoesntExist();

    error CurrencyNotWhitelisted();
    error InvalidCommunityMember();
    error InvalidAmounts();
    error ExceedAmount();

    error KeyNotFound();

    error OnlyNFTCreator();
    error NotOwner();
    error InvalidPrintType();
}
