// SPDX-License-Identifier: MIT
//
//Twitter:https://twitter.com/BABYINU20
//Telegram:https://t.me/BabyinuErc20
//
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BabyInu is ERC20 {
    constructor() ERC20("BabyInu", "BabyInu") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
    }
}
