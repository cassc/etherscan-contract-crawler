// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC20.sol";

contract HABIBI is ERC20 {
    constructor() ERC20("HABIBI", "HABIBI") {
        _mint(msg.sender, 888000000000 * 10 ** decimals());
    }
}