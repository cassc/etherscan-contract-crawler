// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol';

contract DpxToken is ERC20PresetMinterPauser {
  constructor() ERC20PresetMinterPauser('Dopex Governance Token', 'DPX') {
    revokeRole(PAUSER_ROLE, msg.sender);
    _mint(msg.sender, 500000 ether);
  }
}