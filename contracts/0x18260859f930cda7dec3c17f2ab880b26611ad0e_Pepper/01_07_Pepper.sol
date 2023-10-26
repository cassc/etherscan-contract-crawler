/*
    PEPPER🌶️🌶️🌶️🌶️

    Website: https://peppertoken.info
    Telegram: https://t.me/PepperERC20Portal
    X: https://twitter.com/Pepper_ERC20
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pepper is ERC20 {
    constructor() ERC20("Pepper", "PEPPER") {
        _mint(msg.sender, 1000000000 * 10**18);
    }
}