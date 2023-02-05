// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Contract by technopriest#0760
contract Logo is ERC20 {
    constructor() ERC20("Logo Token", "LOGO") {
        // mint 1 million coins
        _mint(msg.sender, 1 * (10**6) * 10**uint256(decimals()));
    }
}