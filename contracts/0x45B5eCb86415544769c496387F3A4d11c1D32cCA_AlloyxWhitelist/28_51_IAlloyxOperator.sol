// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IAlloyx.sol";

/**
 * @title IAlloyxOperator
 * @author AlloyX
 */
interface IAlloyxOperator is IAlloyx {
  /**
   * @notice Alloy DURA Token Value in terms of USDC from all the protocols involved
   * @param _vaultAddress the address of vault
   */
  function getTotalBalanceInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Get additional amount to deposit using the proportion of the component of the vault and total vault value
   * @param _source the source of the third party protocol
   * @param _poolAddress the pool address of the third party protocol
   * @param _tranche the tranche to deposit
   * @param _proportion the proportion to deposit
   * @param _investableUsdc the amount of usdc investable
   */
  function getAdditionalDepositAmount(
    Source _source,
    address _poolAddress,
    uint256 _tranche,
    uint256 _proportion,
    uint256 _investableUsdc
  ) external returns (uint256);

  /**
   * @notice Perform deposit operation to different source
   * @param _source the source of the third party protocol
   * @param _poolAddress the pool address of the third party protocol
   * @param _tranche the tranche to deposit
   * @param _amount the amount to deposit
   */
  function performDeposit(
    Source _source,
    address _poolAddress,
    uint256 _tranche,
    uint256 _amount
  ) external;

  /**
   * @notice Perform withdrawal operation for different source
   * @param _source the source of the third party protocol
   * @param _poolAddress the pool address of the third party protocol
   * @param _tokenId the token ID
   * @param _amount the amount to withdraw
   */
  function performWithdraw(
    Source _source,
    address _poolAddress,
    uint256 _tokenId,
    uint256 _amount,
    WithdrawalStep _step
  ) external;
}