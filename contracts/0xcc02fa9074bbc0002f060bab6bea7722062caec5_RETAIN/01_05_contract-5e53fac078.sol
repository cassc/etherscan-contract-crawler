// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract RETAIN is ERC20 {
    constructor() ERC20("RETAIN", "RETAIN") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}