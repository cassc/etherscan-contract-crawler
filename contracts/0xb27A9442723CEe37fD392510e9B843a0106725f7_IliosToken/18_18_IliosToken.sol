// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol';

contract IliosToken is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("Ilios", "ILO") {}
}