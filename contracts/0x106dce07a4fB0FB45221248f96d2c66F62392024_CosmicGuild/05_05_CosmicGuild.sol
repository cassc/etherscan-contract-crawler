// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CosmicGuild is ERC20("Cosmic Guild", "CG") {
    uint256 constant SUPPLY_CAP = 500_000_000 ether; // 500m total supply

    constructor(address _to) {
        _mint(_to, SUPPLY_CAP);
    }
}