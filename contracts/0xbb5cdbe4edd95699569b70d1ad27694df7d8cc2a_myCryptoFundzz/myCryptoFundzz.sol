/**
 *Submitted for verification at Etherscan.io on 2023-08-23
*/

/*

Website: https://mycryptofunds.pro
Twitter: https://twitter.com/myCryptoFundsX
Telegram: https://t.me/myCryptoFundsETH

Welcome to myCryptoFunds Token. Our solutions allows experienced traders to leverage
their positions up to 10x with our FTMO programs. Choose one of our programs and get funded,
earn bonuses and profit - splits up to 75%.

Your success is our business model. Explore our programs, the features along with the rules
and the limitations and take the leap to become a funded crypto trader.

At myCryptoFunds we care about your success. If you lose, we lose, to become part of our funded
traders you should first understand how it works to avoid any suspension or account termination.

⚠️ This Token will not be launched, it's just part of our marketing. ⚠️

myCryptoFunds (FTMO) Token will be deployed and launched by the following wallet under the
ENS: my-cryptofunds.eth (https://etherscan.io/address/0xae67cb0da7329f3aefb1f90bbf2c32b02198ebb5)

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

contract myCryptoFundzz {
    string public name = "@myCryptoFundsETH";
    string public symbol = "myCryptoFunds";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }
}