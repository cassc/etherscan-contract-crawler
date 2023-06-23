// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract SniwToken is ERC20PresetMinterPauser {
 uint constant _initial_supply = 1000000 * (10**18);
    constructor() ERC20PresetMinterPauser("SniwToken", "SNIW") {
        _mint(msg.sender, _initial_supply);
    }
}