//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TheAD is Context, ERC20, Ownable {
    using SafeMath for uint256;

    uint8 private _decimals = 8;
    uint256 private _Total = 10000000  * 10**_decimals;

    address[] private _TreasuryWallets;
    uint256 private _TreasuryWalletsLen = 1;
    uint256 private _TreasuryWalletsRate = 1;

    address[] private _GuardWallets;
    uint256 private _GuardWalletsLen = 2;
    uint256 private _GuardWalletsRate = 1;

    address[] private _GladiatorsWallets;
    uint256 private _GladiatorsWalletsLen = 10;
    uint256 private _GladiatorsWalletsRate = 1;

    address public _DeadWallet = 0x000000000000000000000000000000000000dEaD;
    uint256 private _DeadWalletRate = 1;

    mapping (address => bool) private _isPrisonList;
    mapping (address => bool) private _isExcludeTax;


    constructor(address _owner)ERC20("The Akragas Decadrachm", "TheAD"){

        transferOwnership(_owner);
        _mint(_owner, _Total);

        // _TreasuryWallets
        for (uint8 i = 0; i < _TreasuryWalletsLen; i++) {
            _TreasuryWallets.push(address(0));
        }

        // _GuardWallets
        for (uint8 i = 0; i < _GuardWalletsLen; i++) {
            _GuardWallets.push(address(0));
        }

        // _GladiatorsWallets
        for (uint8 i = 0; i < _GladiatorsWalletsLen; i++) {
            _GladiatorsWallets.push(address(0));
        }

    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {

        require(!_isPrisonList[from], "Sender in Prison");
        require(!_isPrisonList[to], "Receiver in Prison");

        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        uint256 tax = 0;
        if(!_isExcludeTax[from])
            tax = _taxCalc(from, to, amount);        
        amount = amount - tax;

        _transfer(from, to, amount);
        return true;
    }


    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();

        require(!_isPrisonList[owner], "Sender in Prison");
        require(!_isPrisonList[to], "Receiver in Prison");

        uint256 tax = 0;
        if(!_isExcludeTax[owner])
            tax = _taxCalc(owner, to, amount);        
        amount = amount - tax;

        _transfer(owner, to, amount);
        return true;
    }


    function _taxCalc(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 tax = 0;
        uint256 _tax = 0;

        // _TreasuryWallets
        for (uint8 i = 0; i < _TreasuryWalletsLen; i++) {
            if(_TreasuryWallets[i] != address(0)){
                _tax = calculateRateFee(amount, _TreasuryWalletsRate, _TreasuryWalletsLen);
                tax = tax + _tax;
                _transfer(from, _TreasuryWallets[i], _tax);
            }
        }

        // _GuardWallets
        for (uint8 i = 0; i < _GuardWalletsLen; i++) {
            if(_GuardWallets[i] != address(0)){
                _tax = calculateRateFee(amount, _GuardWalletsRate, _GuardWalletsLen);
                tax = tax + _tax;
                _transfer(from, _GuardWallets[i], _tax);
            }
        }

        // _GladiatorsWallets
        for (uint8 i = 0; i < _GladiatorsWalletsLen; i++) {
            if(_GladiatorsWallets[i] != address(0)){
                _tax = calculateRateFee(amount, _GladiatorsWalletsRate, _GladiatorsWalletsLen);
                tax = tax + _tax;                
                _transfer(from, _GladiatorsWallets[i], _tax);
            }
        }


        _tax = calculateRateFee(amount, _DeadWalletRate, 1);
        tax = tax + _tax;
        _transfer(from, _DeadWallet, _tax);

        return tax;
    }


    function calculateRateFee(uint256 _amount, uint256 _rate, uint256 _len) private view returns (uint256) {        
        return _amount.mul(_rate).div(
            _len * 10**2
        );
    }


    function SetGladiatorWallet(uint8 index, address account) public onlyOwner() {
        require(index < _GladiatorsWalletsLen, "Incorrect Index");
        _GladiatorsWallets[index] = account;
    }

    function SetTheGuardWallet(uint8 index, address account) public onlyOwner() {
        require(index < _GuardWalletsLen, "Incorrect Index");
        _GuardWallets[index] = account;
    }

    function SetTreasuryWallet(uint8 index, address account) public onlyOwner() {
        require(index < _TreasuryWalletsLen, "Incorrect Index");
        _TreasuryWallets[index] = account;
    }

    function ExcludeFromPrison(address account) public onlyOwner() {
        _isPrisonList[account] = false;
    }

    function IncludeInPrison(address account) public onlyOwner() {
        _isPrisonList[account] = true;
    }

    function ExcludeFromTax(address account) public onlyOwner() {
        _isExcludeTax[account] = true;
    }

    function IncludeInTax(address account) public onlyOwner() {
        _isExcludeTax[account] = false;
    }


}