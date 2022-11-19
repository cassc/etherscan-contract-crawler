// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract MultiStableToken is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("Multi Stable", "MUSD") {}

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}