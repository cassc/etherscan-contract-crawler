// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BEP20.sol";

contract TTHCToken is BEP20 {
    constructor() BEP20("TTHC", "TTHC") {
        _mint(msg.sender, 100000000000 * 10**18);
    }
}