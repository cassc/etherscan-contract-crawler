// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract XBEAN is ERC20Permit, ReentrancyGuard {
    constructor() ERC20Permit("xBean", "XBEAN") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}