// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IFluxDesk
 * @author AlloyX
 */
interface IFluxDesk {
  /**
   * @notice Purchase Flux
   * @param _vaultAddress the vault address
   * @param _amount the amount of usdc to purchase by
   */
  function mint(address _vaultAddress, uint256 _amount) external;

  /**
   * @notice Redeem FLUX
   * @param _vaultAddress the vault address
   * @param _amount the amount of FLUX to sell
   */
  function redeem(address _vaultAddress, uint256 _amount) external;

  /**
   * @notice Fidu Value in Vault in term of USDC
   * @param _vaultAddress the pool address of which we calculate the balance
   */
  function getFluxBalanceInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Flux Balance in Vault in term
   * @param _vaultAddress the pool address
   */
  function getFluxBalance(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Redeem FLUX from Vault directly
   * @param _usdcAmount the amount of USDC to sell
   */
  function redeemUsdc(uint256 _usdcAmount) external returns (uint256);
}