// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ICredixOracle
 * @author AlloyX
 */
interface ICredixOracle {
  /**
   * @notice Get the net asset value of vault
   * @param _vaultAddress the vault address to increase USDC value on
   */
  function getNetAssetValueInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Increase the USDC value after the vault provides USDC to credix desk
   * @param _vaultAddress the vault address to increase USDC value on
   * @param _increasedValue the increased value of the vault
   */
  function increaseUsdcValue(address _vaultAddress, uint256 _increasedValue) external;
}