// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./BEP20.sol";

contract ANPToken is BEP20 {
    constructor() BEP20("ANP", "ANP") {
        _mint(msg.sender, 100000000000 * 10**18);
    }
}