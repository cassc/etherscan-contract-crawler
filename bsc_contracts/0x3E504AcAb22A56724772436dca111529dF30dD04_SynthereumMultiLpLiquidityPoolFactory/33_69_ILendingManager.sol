// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ILendingStorageManager} from './ILendingStorageManager.sol';

interface ILendingManager {
  struct Roles {
    address admin;
    address maintainer;
  }

  struct ReturnValues {
    uint256 poolInterest; //accumulated pool interest since last state-changing operation;
    uint256 daoInterest; //acccumulated dao interest since last state-changing operation;
    uint256 tokensOut; //amount of collateral used for a money market operation
    uint256 tokensTransferred; //amount of tokens finally transfered/received from money market (after eventual fees)
    uint256 prevTotalCollateral; //total collateral in the pool (users + LPs) before new operation
  }

  struct InterestSplit {
    uint256 poolInterest; // share of the total interest generated to the LPs;
    uint256 jrtInterest; // share of the total interest generated for jrt buyback;
    uint256 commissionInterest; // share of the total interest generated as dao commission;
  }

  struct MigrateReturnValues {
    uint256 prevTotalCollateral; // prevDepositedCollateral collateral deposited (without last interests) before the migration
    uint256 poolInterest; // poolInterests collateral interests accumalated before the migration
    uint256 actualTotalCollateral; // actualCollateralDeposited collateral deposited after the migration
  }

  event BatchBuyback(
    uint256 indexed collateralIn,
    uint256 JRTOut,
    address receiver
  );

  event BatchCommissionClaim(uint256 indexed collateralOut, address receiver);

  /**
   * @notice deposits collateral into the pool's associated money market
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _collateralAmount amount of collateral to deposit
   * @return returnValues check struct
   */
  function deposit(uint256 _collateralAmount)
    external
    returns (ReturnValues memory returnValues);

  /**
   * @notice withdraw collateral from the pool's associated money market
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _interestTokenAmount amount of interest tokens to redeem
   * @param _recipient the address receiving the collateral from money market
   * @return returnValues check struct
   */
  function withdraw(uint256 _interestTokenAmount, address _recipient)
    external
    returns (ReturnValues memory returnValues);

  /**
   * @notice calculate, split and update the generated interest of the caller pool since last state-changing operation
   * @return returnValues check struct
   */
  function updateAccumulatedInterest()
    external
    returns (ReturnValues memory returnValues);

  /**
   * @notice batches calls to redeem poolData.commissionInterest from multiple pools
   * @dev calculates and update the generated interest since last state-changing operation
   * @param _pools array of pools to redeem commissions from
   * @param _collateralAmounts array of amount of commission to redeem for each pool (matching pools order)
   */
  function batchClaimCommission(
    address[] calldata _pools,
    uint256[] calldata _collateralAmounts
  ) external;

  /**
   * @notice batches calls to redeem poolData.jrtInterest from multiple pools
   * @notice and executes a swap to buy Jarvis Reward Token
   * @dev calculates and update the generated interest since last state-changing operation
   * @param _pools array of pools to redeem collateral from
   * @param _collateralAmounts array of amount of commission to redeem for each pool (matching pools order)
   * @param _collateralAddress address of the pools collateral token (all pools must have the same collateral)
   * @param _swapParams encoded bytes necessary for the swap module
   */
  function batchBuyback(
    address[] calldata _pools,
    uint256[] calldata _collateralAmounts,
    address _collateralAddress,
    bytes calldata _swapParams
  ) external;

  /**
   * @notice sets the address of the implementation of a lending module and its extraBytes
   * @param _id associated to the lending module to be set
   * @param _lendingInfo see lendingInfo struct
   */
  function setLendingModule(
    string calldata _id,
    ILendingStorageManager.LendingInfo calldata _lendingInfo
  ) external;

  /**
   * @notice Add a swap module to the whitelist
   * @param _swapModule Swap module to add
   */
  function addSwapProtocol(address _swapModule) external;

  /**
   * @notice Remove a swap module from the whitelist
   * @param _swapModule Swap module to remove
   */
  function removeSwapProtocol(address _swapModule) external;

  /**
   * @notice sets an address as the swap module associated to a specific collateral
   * @dev the swapModule must implement the IJRTSwapModule interface
   * @param _collateral collateral address associated to the swap module
   * @param _swapModule IJRTSwapModule implementer contract
   */
  function setSwapModule(address _collateral, address _swapModule) external;

  /**
   * @notice set shares on interest generated by a pool collateral on the lending storage manager
   * @param _pool pool address to set shares on
   * @param _daoInterestShare share of total interest generated assigned to the dao
   * @param _jrtBuybackShare share of the total dao interest used to buyback jrt from an AMM
   */
  function setShares(
    address _pool,
    uint64 _daoInterestShare,
    uint64 _jrtBuybackShare
  ) external;

  /**
   * @notice migrates liquidity from one lending module (and money market), to a new one
   * @dev calculates and return the generated interest since last state-changing operation.
   * @dev The new lending module info must be have been previously set in the storage manager
   * @param _newLendingID id associated to the new lending module info
   * @param _newInterestBearingToken address of the interest token of the new money market
   * @param _interestTokenAmount total amount of interest token to migrate from old to new money market
   * @return migrateReturnValues check struct
   */
  function migrateLendingModule(
    string memory _newLendingID,
    address _newInterestBearingToken,
    uint256 _interestTokenAmount
  ) external returns (MigrateReturnValues memory);

  /**
   * @notice migrates pool storage from a deployed pool to a new pool
   * @param _migrationPool Pool from which the storage is migrated
   * @param _newPool address of the new pool
   * @return sourceCollateralAmount Collateral amount of the pool to migrate
   * @return actualCollateralAmount Collateral amount of the new deployed pool
   */
  function migratePool(address _migrationPool, address _newPool)
    external
    returns (uint256 sourceCollateralAmount, uint256 actualCollateralAmount);

  /**
   * @notice Claim leinding protocol rewards of a list of pools
   * @notice _pools List of pools from which claim rewards
   */
  function claimLendingRewards(address[] calldata _pools) external;

  /**
   * @notice returns the conversion between interest token and collateral of a specific money market
   * @param _pool reference pool to check conversion
   * @param _interestTokenAmount amount of interest token to calculate conversion on
   * @return collateralAmount amount of collateral after conversion
   * @return interestTokenAddr address of the associated interest token
   */
  function interestTokenToCollateral(
    address _pool,
    uint256 _interestTokenAmount
  ) external view returns (uint256 collateralAmount, address interestTokenAddr);

  /**
   * @notice returns accumulated interest of a pool since state-changing last operation
   * @dev does not update state
   * @param _pool reference pool to check accumulated interest
   * @return poolInterest amount of interest generated for the pool after splitting the dao share
   * @return commissionInterest amount of interest generated for the dao commissions
   * @return buybackInterest amount of interest generated for the buyback
   * @return collateralDeposited total amount of collateral currently deposited by the pool
   */
  function getAccumulatedInterest(address _pool)
    external
    view
    returns (
      uint256 poolInterest,
      uint256 commissionInterest,
      uint256 buybackInterest,
      uint256 collateralDeposited
    );

  /**
   * @notice returns the conversion between collateral and interest token of a specific money market
   * @param _pool reference pool to check conversion
   * @param _collateralAmount amount of collateral to calculate conversion on
   * @return interestTokenAmount amount of interest token after conversion
   * @return interestTokenAddr address of the associated interest token
   */
  function collateralToInterestToken(address _pool, uint256 _collateralAmount)
    external
    view
    returns (uint256 interestTokenAmount, address interestTokenAddr);
}