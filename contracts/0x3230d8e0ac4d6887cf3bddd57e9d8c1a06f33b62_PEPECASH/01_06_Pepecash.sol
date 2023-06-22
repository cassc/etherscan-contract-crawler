//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * _____                                  __
 * |  __ \                                | | 
 * | |__) |__ _ __   ___   ___  __ _  ___ | |__ 
 * |  ___/ _ \ '_ \ / _ \ / __// _` |/ __|| '_ \ 
 * | |  |  __/ |_) |  __/| |__| (_| |\__ \| | | |
 * |_|   \___| .__/ \___| \___\\__,_||___/|_| |_|
 *           | |
 *           |_|
 *
 * 
 * The Original Pepe Currency. But on Eth.
 *
 * telegram: t.me/pepecasheth
 *
*/

contract PEPECASH is ERC20Burnable {
    uint256 private initialSupply = 1000000000 * (10 ** 18); // Amount of Original Pepecash on Bitcoin
    uint256 private burnInitial = 303808386.14915496 * (10 ** 18); // Amount of Pepecash burnt on Bitcoin

    constructor() ERC20("PEPECASH", "PEPECASH") {
        _mint(msg.sender, initialSupply);
        _burn(msg.sender, burnInitial);
    }
}