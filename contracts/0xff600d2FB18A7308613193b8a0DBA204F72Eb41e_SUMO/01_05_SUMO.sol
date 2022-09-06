// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SUMO is ERC20 {
    constructor() ERC20("SUMO", "SUMO") {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }
}