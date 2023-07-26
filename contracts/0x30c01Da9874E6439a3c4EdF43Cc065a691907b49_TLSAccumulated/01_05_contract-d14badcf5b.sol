// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract TLSAccumulated is ERC20 {
    constructor() ERC20("TLS Accumulated", "TLS") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}