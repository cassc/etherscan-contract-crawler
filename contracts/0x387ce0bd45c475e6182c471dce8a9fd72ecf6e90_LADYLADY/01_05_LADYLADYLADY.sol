// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LADYLADY is ERC20 {
    constructor() ERC20("MiLADYLADY", "MLL") {
        _mint(msg.sender, 10_000_000 * 10 ** decimals());
    }
}