// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AuraCompounderVault.sol";

contract jAURA is AuraCompounderVault {
    constructor()
        AuraCompounderVault(
            address(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF),
            "Jones AURA",
            "jAURA"
        )
    {}
}