// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract MUSK is ERC20 {
    constructor() ERC20("MUSK", "MUSK") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}