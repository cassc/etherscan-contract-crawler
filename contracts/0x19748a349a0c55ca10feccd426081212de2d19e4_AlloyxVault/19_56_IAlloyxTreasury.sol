// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IAlloyxTreasury
 * @author AlloyX
 */
interface IAlloyxTreasury {
  /**
   * @notice Withdraw the protocol fee from one vault, restricted to manager
   * @param _vaultAddress the vault address to collect fee
   */
  function withdrawProtocolFee(address _vaultAddress) external;
}