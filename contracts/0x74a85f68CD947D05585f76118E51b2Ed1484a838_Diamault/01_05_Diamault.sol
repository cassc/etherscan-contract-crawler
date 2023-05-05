// SPDX-License-Identifier: MIT
// https://twitter.com/Diamault_DVT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Diamault is ERC20 {
   constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply_,
        address recipients_
    ) ERC20(name, symbol) {
        _mint(recipients_, totalSupply_);
    }
}