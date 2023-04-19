// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract PepeGPT is ERC20 {
    constructor() ERC20("PepeGPT", "PepeGPT") {
        _mint(msg.sender, 333333333333333 * 10 ** decimals());
    }
}