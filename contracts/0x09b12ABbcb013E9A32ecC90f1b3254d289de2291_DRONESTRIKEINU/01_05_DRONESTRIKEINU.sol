// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DRONESTRIKEINU is ERC20 {
    constructor() ERC20("DRONESTRIKEINU", "OBAMA") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}