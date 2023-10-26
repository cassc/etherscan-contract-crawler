// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IAlloyx} from "./IAlloyx.sol";
import {IAlloyxVaultToken} from "./IAlloyxVaultToken.sol";

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
   * @notice Liquidate the vault by unstaking from all permanent and regular stakers and burn all the governance tokens issued
   */
  function liquidate() external;

  /**
   * @notice Accrue the protocol fee by minting vault tokens to the treasury
   */
  function accrueProtocolFee() external;

  /**
   * @notice A Liquidity Provider can deposit USDC for Alloy Tokens
   * @param _tokenAmount Number of stable coin
   */
  function deposit(uint256 _tokenAmount) external;

  /**
   * @notice An Alloy token holder can deposit their tokens and redeem them for USDC
   * @param _tokenAmount Number of Alloy Tokens
   */
  function withdraw(uint256 _tokenAmount) external;

  /**
   * @notice Claim the available USDC and update the checkpoints
   */
  function claim() external;

  /**
   * @notice Claimable USDC for ALYX stakers
   * @return the claimable USDC for regular staked ALYX
   * @return the claimable USDC for permanent staked ALYX
   */
  function claimable() external view returns (uint256, uint256);


  /**
   * @notice Get address of the vault token
   */
  function getTokenAddress() external returns (address);


  /**
   * @notice The vault token.
   */
   function vaultToken() external view returns (IAlloyxVaultToken);

  /**
   * @notice Convert USDC Amount to Alloyx DURA
   * @param _amount the amount of usdc to convert to DURA token
   */
  function usdcToAlloyxDura(uint256 _amount) external view returns (uint256);

   /**
   * @notice Convert Alloyx DURA to USDC amount
   * @param _amount the amount of DURA token to convert to usdc
   */
  function alloyxDuraToUsdc(uint256 _amount) external view returns (uint256);
}