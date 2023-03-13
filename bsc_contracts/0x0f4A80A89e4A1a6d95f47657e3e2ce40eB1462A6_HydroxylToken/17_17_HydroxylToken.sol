// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol" ;

contract HydroxylToken is ERC20PresetMinterPauser {
    constructor(uint256 initSupply) ERC20PresetMinterPauser("Hydroxyl Token", "HYT") {
        mint(_msgSender(), initSupply) ;
    }
}