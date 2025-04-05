// SPDX-License-Identifier: UNLICENSE

pragma solidity 0.8.24;

contract PrintErrors {
    error AddressNotMarket();
    error AddressNotDesigner();
    error AddressNotAdmin();
    error InvalidUpdate();
    error InvalidCurrency();
    error InvalidRemoval();

    error InvalidAddress();
    error InvalidDrop();

    error RequirementsNotMet();

    error OnlyCollectionCreator();

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
}
