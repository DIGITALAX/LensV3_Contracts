// SPDX-License-Identifier: UNLICENSE

pragma solidity 0.8.24;

import "./PrintAccessControl.sol";
import "./PrintLibrary.sol";
import "./PrintErrors.sol";

contract PrintSplitsData {
    PrintAccessControl public printAccessControl;
    string public symbol;
    string public name;
    address[] private _allCurrencies;

    mapping(address => mapping(uint256 => uint256)) private _designerSplits;
    mapping(address => mapping(uint256 => uint256)) private _fulfillerSplits;
    mapping(address => mapping(uint256 => uint256)) private _treasurySplits;
    mapping(address => mapping(uint256 => uint256)) private _fulfillerBases;
    mapping(address => uint256) private _currencyIndex;
    mapping(address => bool) private _currencies;
    mapping(address => uint256) private _weiConversion;
    mapping(address => uint256) private _currencyToRate;

    event FulfillerSplitSet(
        address fulfiller,
        uint256 printType,
        uint256 split
    );
    event FulfillerBaseSet(address fulfiller, uint256 printType, uint256 split);
    event DesignerSplitSet(address designer, uint256 printType, uint256 split);
    event TreasurySplitSet(address treasury, uint256 printType, uint256 split);
    event CurrencyAdded(address indexed currency);
    event CurrencyRemoved(address indexed currency);
    event OracleUpdated(address indexed currency, uint256 rate);

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

    function setFulfillerSplit(
        address fulfiller,
        uint256 printType,
        uint256 amount
    ) external onlyAdmin {
        _fulfillerSplits[fulfiller][printType] = amount;

        emit FulfillerSplitSet(fulfiller, printType, amount);
    }

    function setFulfillerBase(
        address fulfiller,
        uint256 printType,
        uint256 amount
    ) external onlyAdmin {
        _fulfillerBases[fulfiller][printType] = amount;
        emit FulfillerBaseSet(fulfiller, printType, amount);
    }

    function setDesignerSplit(
        address designer,
        uint256 printType,
        uint256 amount
    ) external onlyAdmin {
        _designerSplits[designer][printType] = amount;
        emit DesignerSplitSet(designer, printType, amount);
    }

    function setTreasurySplit(
        address treasury,
        uint256 printType,
        uint256 amount
    ) external onlyAdmin {
        _treasurySplits[treasury][printType] = amount;
        emit TreasurySplitSet(treasury, printType, amount);
    }

    function addCurrency(
        address currency,
        uint256 weiAmount
    ) external onlyAdmin {
        if (_currencies[currency]) {
            revert PrintErrors.ExistingCurrency();
        }
        _currencies[currency] = true;
        _weiConversion[currency] = weiAmount;
        _allCurrencies.push(currency);
        _currencyIndex[currency] = _allCurrencies.length - 1;
        emit CurrencyAdded(currency);
    }

    function removeCurrency(address currency) external onlyAdmin {
        if (!_currencies[currency]) {
            revert PrintErrors.CurrencyDoesntExist();
        }
        uint256 index = _currencyIndex[currency];
        address lastCurrency = _allCurrencies[_allCurrencies.length - 1];
        _allCurrencies[index] = lastCurrency;
        _currencyIndex[lastCurrency] = index;
        _allCurrencies.pop();
        delete _currencyIndex[currency];
        _currencies[currency] = false;
        _weiConversion[currency] = 0;
        emit CurrencyRemoved(currency);
    }

    function setOraclePriceUSD(
        address currency,
        uint256 rate
    ) public onlyAdmin {
        if (!_currencies[currency]) {
            revert PrintErrors.InvalidCurrency();
        }

        _currencyToRate[currency] = rate;
        emit OracleUpdated(currency, rate);
    }

    function getFulfillerBase(
        address currency,
        uint256 printType
    ) public view returns (uint256) {
        return _fulfillerBases[currency][printType];
    }

    function getFulfillerSplit(
        address currency,
        uint256 printType
    ) public view returns (uint256) {
        return _fulfillerSplits[currency][printType];
    }

    function getDesignerSplit(
        address currency,
        uint256 printType
    ) public view returns (uint256) {
        return _designerSplits[currency][printType];
    }

    function getTreasurySplit(
        address currency,
        uint256 printType
    ) public view returns (uint256) {
        return _treasurySplits[currency][printType];
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function getIsCurrency(address currency) public view returns (bool) {
        return _currencies[currency];
    }

    function getRateByCurrency(address currency) public view returns (uint256) {
        return _currencyToRate[currency];
    }

    function getWeiByCurrency(address currency) public view returns (uint256) {
        return _weiConversion[currency];
    }

    function getAllCurrencies() public view returns (address[] memory) {
        return _allCurrencies;
    }
}
