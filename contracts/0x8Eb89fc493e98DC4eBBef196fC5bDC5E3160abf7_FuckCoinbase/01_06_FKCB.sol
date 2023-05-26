// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FuckCoinbase is ERC20, Ownable {
    constructor(uint256 totalSupply) ERC20("Fuck_Coinbase", "FKCB") {
        _mint(msg.sender, totalSupply);
    }

    function burn(uint256 tokens) external {
        _burn(msg.sender, tokens);
    }
}