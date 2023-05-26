// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

// Sakura ERC20 token contract
contract SakuraToken is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("Sakura", "SKU") {}
}