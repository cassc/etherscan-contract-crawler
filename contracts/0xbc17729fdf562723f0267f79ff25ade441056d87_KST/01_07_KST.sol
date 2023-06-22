// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract KST is ERC20PresetFixedSupply {
    uint256 private constant TOTAL_SUPPLY = 60000000 ether;

    constructor()
        ERC20PresetFixedSupply(
            "KSM Starter Token",
            "KST",
            TOTAL_SUPPLY,
            msg.sender
        )
    {}
}