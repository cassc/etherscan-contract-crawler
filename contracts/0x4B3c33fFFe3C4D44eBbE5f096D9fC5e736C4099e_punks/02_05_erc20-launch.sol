// SPDX-License-Identifier: MIT

// File: erc20-launch.sol


pragma solidity ^0.8.14;
import "./ERC20.sol";


contract punks is ERC20 {
 constructor() ERC20("Crypto Punks", "PUNKS") {
 _mint(msg.sender, 1000000 * 10 ** decimals());
 }
}