// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract Shimmer is ERC20 {
    constructor() ERC20("Shimmer", "SHIM") {
        _mint(msg.sender, 5000000000 * 10 ** decimals());
    }
}