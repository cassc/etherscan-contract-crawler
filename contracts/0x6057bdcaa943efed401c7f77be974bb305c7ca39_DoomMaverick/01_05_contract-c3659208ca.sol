// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract DoomMaverick is ERC20 {
    constructor() ERC20("Doom Maverick", "DMV") {
        _mint(msg.sender, 500000000 * 10 ** decimals());
    }
}