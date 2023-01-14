// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ILendingStorageManager} from './ILendingStorageManager.sol';

interface ILendingModule {
  struct ReturnValues {
    uint256 totalInterest; // total accumulated interest of the pool since last state-changing operation
    uint256 tokensOut; //amount of tokens received from money market (before eventual fees)
    uint256 tokensTransferred; //amount of tokens finally transfered from money market (after eventual fees)
  }

  /**
   * @notice deposits collateral into the money market
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _poolData pool storage information
   * @param _lendingArgs encoded args needed by the specific implementation
   * @param _amount of collateral to deposit
   * @return totalInterest check ReturnValues struct
   * @return tokensOut check ReturnValues struct
   * @return tokensTransferred check ReturnValues struct
   */
  function deposit(
    ILendingStorageManager.PoolStorage calldata _poolData,
    bytes calldata _lendingArgs,
    uint256 _amount
  )
    external
    returns (
      uint256 totalInterest,
      uint256 tokensOut,
      uint256 tokensTransferred
    );

  /**
   * @notice withdraw collateral from the money market
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _poolData pool storage information
   * @param _pool pool address to calculate interest on
   * @param _lendingArgs encoded args needed by the specific implementation
   * @param _amount of interest tokens to redeem
   * @param _recipient address receiving the collateral from money market
   * @return totalInterest check ReturnValues struct
   * @return tokensOut check ReturnValues struct
   * @return tokensTransferred check ReturnValues struct
   */
  function withdraw(
    ILendingStorageManager.PoolStorage calldata _poolData,
    address _pool,
    bytes calldata _lendingArgs,
    uint256 _amount,
    address _recipient
  )
    external
    returns (
      uint256 totalInterest,
      uint256 tokensOut,
      uint256 tokensTransferred
    );

  /**
   * @notice transfer all interest token balance from an old pool to a new one
   * @param _oldPool Address of the old pool
   * @param _newPool Address of the new pool
   * @param _collateral address of collateral token
   * @param _interestToken address of interest token
   * @param _extraArgs encoded args the ILendingModule implementer might need. see ILendingManager.LendingInfo struct
   * @return prevTotalCollateral Total collateral in the old pool
   * @return actualTotalCollateral Total collateral in the new pool
   */
  function totalTransfer(
    address _oldPool,
    address _newPool,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  )
    external
    returns (uint256 prevTotalCollateral, uint256 actualTotalCollateral);

  /**
   * @notice Claim the rewards associated to the bearing tokens of the caller(pool)
   * @param _lendingArgs encoded args needed by the specific implementation
   * @param _collateral Address of the collateral of the pool
   * @param _bearingToken Address of the bearing token of the pool
   * @param _recipient address to which send rewards
   */
  function claimRewards(
    bytes calldata _lendingArgs,
    address _collateral,
    address _bearingToken,
    address _recipient
  ) external;

  /**
   * @notice updates eventual state and returns updated accumulated interest
   * @param _poolAddress reference pool to check accumulated interest
   * @param _poolData pool storage information
   * @param _extraArgs encoded args the ILendingModule implementer might need. see ILendingManager.LendingInfo struct
   * @return totalInterest total amount of interest accumulated
   */
  function getUpdatedInterest(
    address _poolAddress,
    ILendingStorageManager.PoolStorage calldata _poolData,
    bytes calldata _extraArgs
  ) external returns (uint256 totalInterest);

  /**
   * @notice returns accumulated interest of a pool since state-changing last operation
   * @dev does not update state
   * @param _poolAddress reference pool to check accumulated interest
   * @param _poolData pool storage information
   * @param _extraArgs encoded args the ILendingModule implementer might need. see ILendingManager.LendingInfo struct
   * @return totalInterest total amount of interest accumulated
   */
  function getAccumulatedInterest(
    address _poolAddress,
    ILendingStorageManager.PoolStorage calldata _poolData,
    bytes calldata _extraArgs
  ) external view returns (uint256 totalInterest);

  /**
   * @notice returns bearing token associated to the collateral
   * @dev does not update state
   * @param _collateral collateral address to check bearing token
   * @param _extraArgs encoded args the ILendingModule implementer might need. see ILendingManager.LendingInfo struct
   * @return token bearing token
   */
  function getInterestBearingToken(
    address _collateral,
    bytes calldata _extraArgs
  ) external view returns (address token);

  /**
   * @notice returns the conversion between collateral and interest token of a specific money market
   * @param _collateralAmount amount of collateral to calculate conversion on
   * @param _collateral address of collateral token
   * @param _interestToken address of interest token
   * @param _extraArgs encoded args the ILendingModule implementer might need. see ILendingManager.LendingInfo struct
   * @return interestTokenAmount amount of interest token after conversion
   */
  function collateralToInterestToken(
    uint256 _collateralAmount,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  ) external view returns (uint256 interestTokenAmount);

  /**
   * @notice returns the conversion between interest token and collateral of a specific money market
   * @param _interestTokenAmount amount of interest token to calculate conversion on
   * @param _collateral address of collateral token
   * @param _interestToken address of interest token
   * @param _extraArgs encoded args the ILendingModule implementer might need. see ILendingManager.LendingInfo struct
   * @return collateralAmount amount of collateral token after conversion
   */
  function interestTokenToCollateral(
    uint256 _interestTokenAmount,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  ) external view returns (uint256 collateralAmount);
}