// SPDX-License-Identifier: MIT

/*
I'm Gary Gensler and today I want to ban cryptocurrencies in the USA

The only cryptocurrency that will remain is $GaryCL

Telegram: https://t.me/+vHLMKSJTEYoxNjM0
Twitter: https://twitter.com/ClownGaryErc20

*/ 

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GaryClown is ERC20 {
    constructor() ERC20("Gary Clown", "GaryCL") {
        _mint(msg.sender, 1_000_000_000 ether);
    }
}