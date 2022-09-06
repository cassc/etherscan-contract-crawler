// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./ERC20Detailed.sol";

contract WBT is ERC20Detailed {
    constructor() ERC20Detailed("WBT", "WBT", 8, 300_000_000_00000000) {
    }
}