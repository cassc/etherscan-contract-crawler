// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {AuraBaseCompounderVault} from "src/compounder/vaults/AuraBaseCompounderVault.sol";

contract AuraCompounderVault is AuraBaseCompounderVault {
    constructor() AuraBaseCompounderVault(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF, "Wrapped Jones AURA", "wjAURA") {}
}