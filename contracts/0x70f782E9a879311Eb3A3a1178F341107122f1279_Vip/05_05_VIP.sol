// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Vip is ERC20 {
    constructor() ERC20("VIP", "VIP") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}