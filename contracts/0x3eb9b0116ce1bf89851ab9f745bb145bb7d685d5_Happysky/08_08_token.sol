// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract Happysky is ERC20Permit, ReentrancyGuard {
    constructor() ERC20Permit("Happysky", "HASKY") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}