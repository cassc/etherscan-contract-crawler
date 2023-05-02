/**
 *Submitted for verification at Etherscan.io on 2023-04-28
*/

//SPDX-License-Identifier: UNLICENSED

/**
One dollar liquidity, for the people.  enj0y.
The goal is to bring $DP to over $1million market cap from just $1 liquidity to start.

Starting with 1% buy and 2% sell tax, all funds would be added to further the liquidity goal of $1million.


**/

pragma solidity ^0.8.0;

contract DollarPEPE {
    string public constant name = "DollarPEPE";
    string public constant symbol = "DP";
    uint8 public constant decimals = 18;
    uint256 public constant initialSupply = 69000000000 * 10**uint256(decimals);
    uint256 public totalSupply;
    address payable public creator;
    uint256 public buyTaxPercentage = 1;
    uint256 public sellTaxPercentage = 2;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        creator = payable(msg.sender);
        totalSupply = initialSupply;
        balances[creator] = totalSupply;
        emit Transfer(address(0), creator, totalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid recipient address");
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        uint256 tax = (_value * sellTaxPercentage) / 100;
        balances[creator] += tax;
        balances[_to] += _value - tax;
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, creator, tax);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid recipient address");
        require(balances[_from] >= _value, "Insufficient balance");
        require(allowed[_from][msg.sender] >= _value, "Allowance exceeded");
        balances[_from] -= _value;
        uint256 tax = (_value * sellTaxPercentage) / 100;
        balances[creator] += tax;
        balances[_to] += _value - tax;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        emit Transfer(_from, creator, tax);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}