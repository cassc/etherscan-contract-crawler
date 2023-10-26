// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract X is ERC20{
    constructor() ERC20("X", "X") {
        _mint(msg.sender, 1000000000 * 1e18);
    }
}