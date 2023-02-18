/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyAltcoin {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balances[msg.sender] = totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(_value <= balances[msg.sender], "Insufficient balance");

        uint256 fee = (_value * 5) / 100; // Calculate 5% fee
        uint256 valueAfterFee = _value - fee; // Calculate value after fee
        balances[msg.sender] -= _value; // Deduct balance from sender
        balances[_to] += valueAfterFee; // Add balance to receiver
        balances[0x073aB83DEF8b5629a4218AFB01Fc144240ECa4f0] += fee; // Add fee to your address

        emit Transfer(msg.sender, _to, valueAfterFee); // Emit Transfer event
        emit Transfer(msg.sender, 0x073aB83DEF8b5629a4218AFB01Fc144240ECa4f0, fee); // Emit Transfer event for fee transfer

        return true;
        }


    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Invalid address");

        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowances[_from][msg.sender], "Insufficient allowance");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}