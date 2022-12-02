// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./BEP20.sol";

contract MockBEP20 is BEP20 {
    constructor(
        string memory name,
        string memory symbol
    ) public BEP20(name, symbol) {
        _mint(msg.sender, 100000000 ether);
    }
}