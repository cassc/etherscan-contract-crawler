// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract EnoToken is ERC20 {
    constructor() ERC20("EnoToken", "ENO") {
        _mint(msg.sender, 25000000 * 1e18);
    }
}
