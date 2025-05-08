// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./AutographLibrary.sol";
import "./AutographErrors.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AutographData {
    using EnumerableSet for EnumerableSet.AddressSet;

    AutographAccessControl public autographAccessControl;
    EnumerableSet.AddressSet private _allCurrencies;
    string public symbol;
    string public name;
    uint256 private _vig;
    uint256 private _hoodieBase;
    uint256 private _shirtBase;

    mapping(address => mapping(uint256 => uint256)) private _designerSplits;
    mapping(address => mapping(uint256 => uint256)) private _fulfillerSplits;
    mapping(address => mapping(uint256 => uint256)) private _fulfillerBases;
    mapping(address => AutographLibrary.Currency) private _currencies;

    event FulfillerSplitSet(
        address fulfiller,
        uint256 printType,
        uint256 split
    );
    event FulfillerBaseSet(address fulfiller, uint256 printType, uint256 split);
    event DesignerSplitSet(address designer, uint256 printType, uint256 split);
    event CurrencyAdded(address indexed currency);
    event CurrencyRemoved(address indexed currency);
    event OracleUpdated(address indexed currency, uint256 rate);

    modifier onlyAdmin() {
        if (!autographAccessControl.isAdmin(msg.sender)) {
            revert AutographErrors.AddressInvalid();
        }
        _;
    }

    constructor(address _autographAccessControl) {
        symbol = "AD";
        name = "AutographData";
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
    }

    function setVig(uint256 newVig) public onlyAdmin {
        _vig = newVig;
    }

    function setHoodieBase(uint256 newBase) public onlyAdmin {
        _hoodieBase = newBase;
    }

    function setShirtBase(uint256 newBase) public onlyAdmin {
        _shirtBase = newBase;
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

    function addCurrency(
        address currency,
        uint256 weiAmount,
        uint256 rate
    ) external onlyAdmin {
        if (_allCurrencies.contains(currency)) {
            revert AutographErrors.ExistingCurrency();
        }

        _allCurrencies.add(currency);

        _currencies[currency].weiAmount = weiAmount;
        _currencies[currency].rate = rate;

        emit CurrencyAdded(currency);
    }

    function removeCurrency(address currency) external onlyAdmin {
        if (!_allCurrencies.contains(currency)) {
            revert AutographErrors.CurrencyDoesntExist();
        }

        _allCurrencies.remove(currency);
        delete _currencies[currency];

        emit CurrencyRemoved(currency);
    }

    function setAutographAccessControl(
        address _autographAccessControl
    ) public onlyAdmin {
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
    }

    function getFulfillerBase(
        address fulfiller,
        uint256 printType
    ) public view returns (uint256) {
        return _fulfillerBases[fulfiller][printType];
    }

    function getFulfillerSplit(
        address fulfiller,
        uint256 printType
    ) public view returns (uint256) {
        return _fulfillerSplits[fulfiller][printType];
    }

    function getDesignerSplit(
        address designer,
        uint256 printType
    ) public view returns (uint256) {
        return _designerSplits[designer][printType];
    }

    function getIsCurrency(address currency) public view returns (bool) {
        return _allCurrencies.contains(currency);
    }

    function getCurrencyWei(address currency) public view returns (uint256) {
        return _currencies[currency].weiAmount;
    }

    function getCurrencyRate(address currency) public view returns (uint256) {
        return _currencies[currency].rate;
    }

    function getAllCurrencies() public view returns (address[] memory) {
        return _allCurrencies.values();
    }

    function getVig() public view returns (uint256) {
        return _vig;
    }

    function getHoodieBase() public view returns (uint256) {
        return _hoodieBase;
    }

    function getShirtBase() public view returns (uint256) {
        return _shirtBase;
    }
}
