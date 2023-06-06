//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Baozou is Ownable, ERC20 
{
    using SafeMath for uint256;

    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;

    address public pair;
    
    mapping(address => bool) public blacklists;
    uint256 public taxPercentage = 5;

    uint public deployTimestamp;

    address public presaleAddress = address(0x19859f152613c192f9C1cB0Beb37aD46690A05AC);

    constructor(
        uint256 _totalSupply) 
        ERC20("Baozou", "BAOZOU") 
    {
        _mint(msg.sender, _totalSupply);
        deployTimestamp = block.timestamp;
    }

    function setPair(
        address _pair)
        external 
        onlyOwner
    {
        pair = _pair;
    }

    function setTaxation(
        uint _taxPercentage)
        external
        onlyOwner 
    {
        require(_taxPercentage <= 5);
        taxPercentage = _taxPercentage;    
    }

    function blacklist(
        address _address, 
        bool _isBlacklisting) 
        external 
        onlyOwner 
    {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(
        bool _limited,
        uint256 _maxHoldingAmount, 
        uint256 _minHoldingAmount) 
        external 
        onlyOwner 
    {
        limited = _limited;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount) 
        override 
        internal 
        virtual 
    {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        //if (pair == address(0)) 
        //{
        //    require(from == owner() || to == owner(), "trading is not started");
        //    return;
        //}

        if (limited && from == pair) 
        {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }

    function burn(
        uint256 value) 
        external 
    {
        _burn(msg.sender, value);
    }

    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount) 
        public 
        override 
        returns (bool) 
    {
        // sale tax
        if (sender != address(this) && 
            recipient == pair && 
            _isTaxSeason(block.timestamp)) 
        {
            (uint net, uint tax) = _calcTax(amount);
            _takeFee(sender, tax);
            super.transferFrom(sender, recipient, net);
        } 
        else 
        {
            super.transferFrom(sender, recipient, amount);
        }

        return true;
    }

    function _isTaxSeason(
        uint time) 
        private 
        view 
        returns (bool)
    {
        return time < deployTimestamp + 12 hours;
    }

    function _calcTax(
        uint amount) 
        private 
        view 
        returns(uint, uint)
    {
        uint256 taxAmount = amount.mul(taxPercentage).div(100);
        uint256 netAmount = amount.sub(taxAmount);
        return (netAmount, taxAmount);
    }

    function _takeFee(
        address from, 
        uint amount) 
        private
    {
        _transfer(from, address(this), amount);
    }

    function sendTaxes() 
        external
    {
        _transfer(address(this), presaleAddress, balanceOf(address(this)));
    }
}