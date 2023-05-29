// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol';

contract RdpxToken is ERC20PresetMinterPauser {
  constructor() ERC20PresetMinterPauser('Dopex Rebate Token', 'rDPX') {
    revokeRole(PAUSER_ROLE, msg.sender);
    // Initial supply set to 2.25 million
    // Breakdown:
    // 2 million for farming rewards
    // 200k for airdrops
    // 50k for initial uniswap liquidity
    _mint(msg.sender, 2250000 ether);
  }
}