// ____   ___  ____ ______        _____  ____  _     ____  
//| __ ) / _ \/ ___/ ___\ \      / / _ \|  _ \| |   |  _ \ 
//|  _ \| | | \___ \___ \\ \ /\ / / | | | |_) | |   | | | |
//| |_) | |_| |___) |__) |\ V  V /| |_| |  _ <| |___| |_| |
//|____/ \___/|____/____/  \_/\_/  \___/|_| \_\_____|____/ 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BossWorld
{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    address public taxWallet;

    uint256 public buyTaxPercentage = 2;
    uint256 public sellTaxPercentage = 2;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Buy(address indexed buyer, uint256 amount, uint256 tax);
    event Sell(address indexed seller, uint256 amount, uint256 tax);

    constructor() 
    {
        name = "BossWorld";
        symbol = "BOSS";
        decimals = 18;
        totalSupply = 21000000000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        taxWallet = 0xdb12C246568533Bf3Cc52C9f3f558274Af0a970d;
    }

    function transfer(address to, uint256 value) external 
    {
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        uint256 tax = calculateTax(value, msg.sender == address(this));
        uint256 afterTaxValue = value - tax;

        balanceOf[msg.sender] -= value;
        balanceOf[to] += afterTaxValue;

        emit Transfer(msg.sender, to, afterTaxValue);

        if (tax > 0) 
        {
            balanceOf[taxWallet] += tax;
            emit Sell(msg.sender, value, tax);
        }
    }

    function calculateTax(uint256 value, bool isBuying) internal view returns (uint256) 
    {
        uint256 taxPercentage = isBuying ? buyTaxPercentage : sellTaxPercentage;
        return (value * taxPercentage) / 100;
    }
}