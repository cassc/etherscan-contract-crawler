// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface IUSDCBurnableSourceBridge {
  // Emit an event indicating that the USDC has been burned
  event AllLockedUSDCBurnt(address indexed sender);

  /**
   * @dev this executes a burn on the source
   * chain.
   */
  function burnAllLockedUSDC() external;
}