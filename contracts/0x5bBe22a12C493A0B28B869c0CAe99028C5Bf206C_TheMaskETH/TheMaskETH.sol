/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TheMaskETH {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    uint256 public taxRate;  // The tax rate in percentage (e.g., 5 for 5% tax)

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Tax(address indexed from, address indexed to, uint256 value, uint256 taxAmount);

    constructor() {
        name = "TheMaskETH";
        symbol = "MSK";
        decimals = 18;
        totalSupply = 1000000000 * 10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;

        owner = msg.sender;
        taxRate = 5;  // Default tax rate of 5%
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    function setTaxRate(uint256 _newTaxRate) external onlyOwner {
        taxRate = _newTaxRate;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid address");

        uint256 taxAmount = (_value * taxRate) / 100;
        uint256 transferAmount = _value - taxAmount;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[address(this)] += taxAmount;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Tax(msg.sender, address(this), _value, taxAmount);

        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0), "Invalid address");

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        require(_to != address(0), "Invalid address");

        uint256 taxAmount = (_value * taxRate) / 100;
        uint256 transferAmount = _value - taxAmount;

        balanceOf[_from] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[address(this)] += taxAmount;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, transferAmount);
        emit Tax(_from, address(this), _value, taxAmount);

        return true;
    }
}