/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract DOUHOT {
    string public name = "DOH OUT";
    string public symbol = "HRDC";
    uint256 public totalSupply = 1000000000 * 10 ** 18;
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;

    address public marketingWallet = 0xB58F5dDc2838588d922fae2F406afF20599D6ab3;
    address public developmentWallet = 0x813b3947DC9deAD3A73D22EF4900F827d581507A;

    uint256 public liquidityFee = 3;
    uint256 public marketingFee = 1;
    uint256 public developmentFee = 1;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 liquidityAmount = _value * liquidityFee / 100;
        uint256 marketingAmount = _value * marketingFee / 100;
        uint256 developmentAmount = _value * developmentFee / 100;
        uint256 transferAmount = _value - liquidityAmount - marketingAmount - developmentAmount;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[marketingWallet] += marketingAmount;
        balanceOf[developmentWallet] += developmentAmount;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, marketingWallet, marketingAmount);
        emit Transfer(msg.sender, developmentWallet, developmentAmount);
        emit Transfer(msg.sender, address(this), liquidityAmount);

        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}