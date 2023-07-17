// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Whaly is ERC20 {
    uint256 total_supply = 1_000_000_000 ether;
    constructor() ERC20("Whaly", "WHALY") {
        _mint(msg.sender, total_supply);
    }
}