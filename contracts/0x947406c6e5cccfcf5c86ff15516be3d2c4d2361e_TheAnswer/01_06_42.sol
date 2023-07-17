//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 *    _____ ________  
 *   /  |  |\_____  \ 
 *  /   |  |_/  ____/ 
 * /    ^   /       \ 
 * \____   |\_______ \
 *      |__|        \/
 *
 * 
 * The Answer to the Ultimate Question of Life, the Universe, and Everything
 *
 * https://t.me/answertoeverything
 * 
*/

contract TheAnswer is ERC20Burnable {
  uint256 private initialSupply = 42 * (10 ** 18); // No more than 42

  constructor() ERC20("42", "42") {
    _mint(msg.sender, initialSupply);
  }
}