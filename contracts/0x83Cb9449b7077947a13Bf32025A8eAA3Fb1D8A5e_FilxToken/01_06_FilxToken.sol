// contracts/FilxToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title FilxToken
 */
contract FilxToken is ERC20, ERC20Burnable {
    constructor(address account, uint256 amount) ERC20("Filx Token", "FILX") {
        _mint(account, amount);
    }
}