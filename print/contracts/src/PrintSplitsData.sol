// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./PrintAccessControl.sol";
import "./PrintLibrary.sol";
import "./PrintErrors.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PrintSplitsData {
    using EnumerableSet for EnumerableSet.AddressSet;

    PrintAccessControl public printAccessControl;
    string public symbol;
    string public name;
    EnumerableSet.AddressSet private _allCurrencies;

    mapping(address => mapping(uint8 => PrintLibrary.Splits))
        private _splitsToPrintType;
    mapping(address => PrintLibrary.Currency) private _currencyDetails;

    event SplitsSet(
        address currency,
        uint256 fulfillerSplit,
        uint256 fulfillerBase,
        uint8 printType
    );
    event CurrencyAdded(
        address indexed currency,
        uint256 weiAmount,
        uint256 rate
    );
    event CurrencyRemoved(address indexed currency);

    modifier onlyAdmin() {
        if (!printAccessControl.isAdmin(msg.sender)) {
            revert PrintErrors.AddressNotAdmin();
        }
        _;
    }

    constructor(address printAccessControlAddress) {
        printAccessControl = PrintAccessControl(printAccessControlAddress);
        symbol = "PSD";
        name = "PrintSplitsData";
    }

    function setSplits(
        address currency,
        uint256 fulfillerSplit,
        uint256 fulfillerBase,
        uint8 printType
    ) external onlyAdmin {
        _splitsToPrintType[currency][printType] = PrintLibrary.Splits({
            fulfillerSplit: fulfillerSplit,
            fulfillerBase: fulfillerBase
        });

        emit SplitsSet(currency, fulfillerSplit, fulfillerBase, printType);
    }

    function addCurrency(
        address currency,
        uint256 weiAmount,
        uint256 rate
    ) external onlyAdmin {
        if (_allCurrencies.contains(currency)) {
            revert PrintErrors.ExistingCurrency();
        }
        _currencyDetails[currency] = PrintLibrary.Currency({
            weiAmount: weiAmount,
            rate: rate
        });
        _allCurrencies.add(currency);
        emit CurrencyAdded(currency, weiAmount, rate);
    }

    function removeCurrency(address currency) external onlyAdmin {
        if (!_allCurrencies.contains(currency)) {
            revert PrintErrors.CurrencyDoesntExist();
        }

        _allCurrencies.remove(currency);
        delete _currencyDetails[currency];
        emit CurrencyRemoved(currency);
    }

    function getFulfillerBase(
        address currency,
        uint8 printType
    ) public view returns (uint256) {
        return _splitsToPrintType[currency][printType].fulfillerBase;
    }

    function getFulfillerSplit(
        address currency,
        uint8 printType
    ) public view returns (uint256) {
        return _splitsToPrintType[currency][printType].fulfillerSplit;
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function getIsCurrency(address currency) public view returns (bool) {
        return _allCurrencies.contains(currency);
    }

    function getCurrencyRate(address currency) public view returns (uint256) {
        return _currencyDetails[currency].rate;
    }

    function getCurrencyWei(address currency) public view returns (uint256) {
        return _currencyDetails[currency].weiAmount;
    }

    function getAllCurrencies() public view returns (address[] memory) {
        return _allCurrencies.values();
    }
}
