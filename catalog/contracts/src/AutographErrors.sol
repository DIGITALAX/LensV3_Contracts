// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

contract AutographErrors {
    error AddressInvalid();
    error Existing();
    error CantRemoveSelf();
    error NotAgent();

    error AddressNotVerified();
    error CollectionNotFound();

    error InvalidAddress();
    error CurrencyNotWhitelisted();
    error ExceedAmount();
    error InvalidAmounts();
    error InvalidType();

    error AddressNotAdmin();
    error ExistingCurrency();
    error CurrencyDoesntExist();
    error InvalidCurrency();

    error KeyNotFound();
}
