// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract FusionX is ERC20, ReentrancyGuard {
    constructor() ERC20("FusionX", "FusionX") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}