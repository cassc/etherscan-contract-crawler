// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract KeyTangoToken is ERC20PresetMinterPauser {
     constructor() public ERC20PresetMinterPauser("keyTango Token", "TANGO") {}

     function removeMinterRole(address owner) external { 
          revokeRole(MINTER_ROLE, owner);
     }
}