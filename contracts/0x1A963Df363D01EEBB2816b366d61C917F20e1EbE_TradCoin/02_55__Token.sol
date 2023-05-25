// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract TradCoin is ERC20 {
    constructor(string memory name, string memory id) ERC20(name, id, 18) {
        _mint(msg.sender, 69420000000 * 10 ** 18);
    }
}