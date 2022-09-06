// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./ERC20Detailed.sol";

contract SSHK is ERC20Detailed {
    constructor() ERC20Detailed("SSHK", "SSHK", 8, 1_000_00000000) {
    }
}