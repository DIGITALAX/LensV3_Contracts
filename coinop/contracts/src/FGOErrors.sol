// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

contract FGOErrors {
    error AddressInvalid();
    error Existing();
    error CantRemoveSelf();

    error InvalidAmount();
    error InvalidChild();
}
