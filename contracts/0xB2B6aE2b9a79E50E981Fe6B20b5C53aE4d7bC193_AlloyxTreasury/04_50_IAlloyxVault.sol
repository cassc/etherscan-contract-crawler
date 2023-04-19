// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IAlloyx.sol";

/**
 * @title IAlloyxVault
 * @author AlloyX
 */
interface IAlloyxVault is IAlloyx {
  /**
   * @notice Start the vault by setting up the portfolio of the vault and initial depositors' info
   * @param _components the initial setup of the portfolio for this vault
   * @param _usdcDepositorArray the array of DepositAmount containing the amount and address of the USDC depositors
   * @param _alyxDepositorArray the array of DepositAmount containing the amount and address of the ALYX depositors
   * @param _totalUsdc total amount of USDC to start the vault with
   */
  function startVault(
    Component[] calldata _components,
    DepositAmount[] memory _usdcDepositorArray,
    DepositAmount[] memory _alyxDepositorArray,
    uint256 _totalUsdc
  ) external;

  /**
   * @notice Reinstate governance called by manager contract only
   * @param _alyxDepositorArray the array of DepositAmount containing the amount and address of the ALYX depositors
   */
  function reinstateGovernance(DepositAmount[] memory _alyxDepositorArray) external;

  /**
   * @notice Collect all available protocol fee up to the moment
   */
  function collectProtocolFee() external;

  /**
   * @notice Liquidate the vault by unstaking from all permanent and regular stakers and burn all the governance tokens issued
   */
  function liquidate() external;
}