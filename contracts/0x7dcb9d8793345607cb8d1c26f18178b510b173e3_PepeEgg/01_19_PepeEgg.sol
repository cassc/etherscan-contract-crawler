// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract PepeEgg is ERC20PresetMinterPauser {
 uint constant _initial_supply = 10000 * (10**18);
    constructor() ERC20PresetMinterPauser("PepeEgg", "PEGG") {
        _mint(msg.sender, _initial_supply);
    }
}