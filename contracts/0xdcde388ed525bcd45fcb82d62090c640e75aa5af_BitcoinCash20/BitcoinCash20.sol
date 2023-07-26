/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

// SPDX-License-Identifier: MIT

//    Website: https://bch.info/en/
//    Telegram: https://t.me/BitcoinBCH
//    Twitter: https://twitter.com/bitcoincashorg
//    Github https://github.com/bchinfo/bch.info

pragma solidity ^0.8.0;

contract BitcoinCash20 {
    string public name = "Bitcoin Cash 2.0";
    string public symbol = "BCH2";
    uint256 public totalSupply = 19436288 * 10**18; // 19,436,288 tokens with 18 decimal places
    uint8 public decimals = 18;

    mapping(address => uint256) private balances;
    address private deadWallet = 0x000000000000000000000000000000000000dEaD;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Invalid recipient address");
        require(_value <= balances[msg.sender], "Insufficient balance");

        uint256 taxAmount = (_value * 55) / 100;
        uint256 transferAmount = _value - taxAmount;

        balances[msg.sender] -= _value;
        balances[_to] += transferAmount;
        balances[deadWallet] += taxAmount;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, deadWallet, taxAmount);

        return true;
    }

    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }
}