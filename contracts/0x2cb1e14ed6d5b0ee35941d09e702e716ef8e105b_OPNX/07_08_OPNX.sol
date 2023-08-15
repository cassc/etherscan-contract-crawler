// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract OPNX is ERC20, ReentrancyGuard {
    constructor() ERC20("OPNX", "OPNX") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}