/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

// SPDX-License-Identifier: MIT
 /**
   * @title PericoCoin
   * @dev ContractDescription
   * @custom:dev-run-script file_path
   */
  contract ContractName {}
pragma solidity ^0.8.4;

contract PericoCoin {
    string public name = "PericoCoin";
    string public symbol = "PERICO";
    uint256 public totalSupply = 400000000000000;
    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = totalSupply;

        // Distribute tokens
        uint256 liquidityTokens = totalSupply * 88 / 100;
        uint256 centralizedExchangeTokens = totalSupply * 89 / 1000;
        uint256 developmentTokens = totalSupply / 100;
        uint256 marketingTokens = totalSupply * 11 / 1000;

        balanceOf[msg.sender] -= liquidityTokens + centralizedExchangeTokens + developmentTokens + marketingTokens;
        balanceOf[address(0)] = liquidityTokens;
        balanceOf[address(this)] = centralizedExchangeTokens;
        balanceOf[0x963B44ADDa704184c2BD198a7559D85bEf765FB3] = developmentTokens;
        balanceOf[0x57DFE0893536250Fd3f5E5fBeb1E46326c4E6Ac4] = marketingTokens;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "PericoCoin: transfer to zero address");
        require(balanceOf[msg.sender] >= amount, "PericoCoin: insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
}