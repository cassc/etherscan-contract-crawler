// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./IFuseFeeDistributor.sol";
import "./ComptrollerStorage.sol";
import "./ComptrollerInterface.sol";
import "./InterestRateModel.sol";

contract CTokenAdminStorage {
  /*
   * Administrator for Fuse
   */
  address payable public fuseAdmin;

  /**
   * @dev LEGACY USE ONLY: Administrator for this contract
   */
  address payable internal __admin;

  /**
   * @dev LEGACY USE ONLY: Whether or not the Fuse admin has admin rights
   */
  bool internal __fuseAdminHasRights;

  /**
   * @dev LEGACY USE ONLY: Whether or not the admin has admin rights
   */
  bool internal __adminHasRights;
}

contract CTokenStorage is CTokenAdminStorage {
  /**
   * @dev Guard variable for re-entrancy checks
   */
  bool internal _notEntered;

  /**
   * @notice EIP-20 token name for this token
   */
  string public name;

  /**
   * @notice EIP-20 token symbol for this token
   */
  string public symbol;

  /**
   * @notice EIP-20 token decimals for this token
   */
  uint8 public decimals;

  /*
   * Maximum borrow rate that can ever be applied (.0005% / block)
   */
  uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

  /*
   * Maximum fraction of interest that can be set aside for reserves + fees
   */
  uint256 internal constant reserveFactorPlusFeesMaxMantissa = 1e18;

  /*
   * LEGACY USE ONLY: Pending administrator for this contract
   */
  address payable private __pendingAdmin;

  /**
   * @notice Contract which oversees inter-cToken operations
   */
  ComptrollerInterface public comptroller;

  /**
   * @notice Model which tells what the current interest rate should be
   */
  InterestRateModel public interestRateModel;

  /*
   * Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
   */
  uint256 internal initialExchangeRateMantissa;

  /**
   * @notice Fraction of interest currently set aside for admin fees
   */
  uint256 public adminFeeMantissa;

  /**
   * @notice Fraction of interest currently set aside for Fuse fees
   */
  uint256 public fuseFeeMantissa;

  /**
   * @notice Fraction of interest currently set aside for reserves
   */
  uint256 public reserveFactorMantissa;

  /**
   * @notice Block number that interest was last accrued at
   */
  uint256 public accrualBlockNumber;

  /**
   * @notice Accumulator of the total earned interest rate since the opening of the market
   */
  uint256 public borrowIndex;

  /**
   * @notice Total amount of outstanding borrows of the underlying in this market
   */
  uint256 public totalBorrows;

  /**
   * @notice Total amount of reserves of the underlying held in this market
   */
  uint256 public totalReserves;

  /**
   * @notice Total amount of admin fees of the underlying held in this market
   */
  uint256 public totalAdminFees;

  /**
   * @notice Total amount of Fuse fees of the underlying held in this market
   */
  uint256 public totalFuseFees;

  /**
   * @notice Total number of tokens in circulation
   */
  uint256 public totalSupply;

  /*
   * Official record of token balances for each account
   */
  mapping(address => uint256) internal accountTokens;

  /*
   * Approved token transfer amounts on behalf of others
   */
  mapping(address => mapping(address => uint256)) internal transferAllowances;

  /**
   * @notice Container for borrow balance information
   * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
   * @member interestIndex Global borrowIndex as of the most recent balance-changing action
   */
  struct BorrowSnapshot {
    uint256 principal;
    uint256 interestIndex;
  }

  /*
   * Mapping of account addresses to outstanding borrow balances
   */
  mapping(address => BorrowSnapshot) internal accountBorrows;

  /*
   * Share of seized collateral that is added to reserves
   */
  uint256 public constant protocolSeizeShareMantissa = 2.8e16; //2.8%

  /*
   * Share of seized collateral taken as fees
   */
  uint256 public constant feeSeizeShareMantissa = 1e17; //10%
}

abstract contract CTokenInterface is CTokenStorage {
  /**
   * @notice Indicator that this is a CToken contract (for inspection)
   */
  function isCToken() external virtual returns (bool) {
    return true;
  }

  /**
   * @notice Indicator that this is or is not a CEther contract (for inspection)
   */
  function isCEther() external virtual returns (bool) {
    return false;
  }

  /*** Market Events ***/

  /**
   * @notice Event emitted when interest is accrued
   */
  event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

  /**
   * @notice Event emitted when tokens are minted
   */
  event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

  /**
   * @notice Event emitted when tokens are redeemed
   */
  event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

  /**
   * @notice Event emitted when underlying is borrowed
   */
  event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

  /**
   * @notice Event emitted when a borrow is repaid
   */
  event RepayBorrow(address payer, address borrower, uint256 repayAmount, uint256 accountBorrows, uint256 totalBorrows);

  /**
   * @notice Event emitted when a borrow is liquidated
   */
  event LiquidateBorrow(
    address liquidator,
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral,
    uint256 seizeTokens
  );

  /*** Admin Events ***/

  /**
   * @notice Event emitted when interestRateModel is changed
   */
  event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

  /**
   * @notice Event emitted when the reserve factor is changed
   */
  event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

  /**
   * @notice Event emitted when the reserves are added
   */
  event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

  /**
   * @notice Event emitted when the reserves are reduced
   */
  event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

  /**
   * @notice Event emitted when the admin fee is changed
   */
  event NewAdminFee(uint256 oldAdminFeeMantissa, uint256 newAdminFeeMantissa);

  /**
   * @notice Event emitted when the Fuse fee is changed
   */
  event NewFuseFee(uint256 oldFuseFeeMantissa, uint256 newFuseFeeMantissa);

  /**
   * @notice EIP20 Transfer event
   */
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /**
   * @notice EIP20 Approval event
   */
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /*** User Interface ***/

  function transfer(address dst, uint256 amount) external virtual returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external virtual returns (bool);

  function approve(address spender, uint256 amount) external virtual returns (bool);

  function allowance(address owner, address spender) external view virtual returns (uint256);

  function balanceOf(address owner) external view virtual returns (uint256);

  function balanceOfUnderlying(address owner) external virtual returns (uint256);

  function getAccountSnapshot(address account)
    external
    view
    virtual
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function borrowRatePerBlock() external view virtual returns (uint256);

  function supplyRatePerBlock() external view virtual returns (uint256);

  function totalBorrowsCurrent() external virtual returns (uint256);

  function borrowBalanceCurrent(address account) external virtual returns (uint256);

  function borrowBalanceStored(address account) public view virtual returns (uint256);

  function exchangeRateCurrent() public virtual returns (uint256);

  function exchangeRateStored() public view virtual returns (uint256);

  function getCash() external view virtual returns (uint256);

  function accrueInterest() public virtual returns (uint256);

  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external virtual returns (uint256);

  /*** Admin Functions ***/

  function _setReserveFactor(uint256 newReserveFactorMantissa) external virtual returns (uint256);

  function _setInterestRateModel(InterestRateModel newInterestRateModel) public virtual returns (uint256);
}

contract CErc20Storage is CTokenStorage {
  /**
   * @notice Underlying asset for this CToken
   */
  address public underlying;
}

abstract contract CErc20Interface is CTokenInterface, CErc20Storage {
  /*** User Interface ***/

  function mint(uint256 mintAmount) external virtual returns (uint256);

  function redeem(uint256 redeemTokens) external virtual returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external virtual returns (uint256);

  function borrow(uint256 borrowAmount) external virtual returns (uint256);

  function repayBorrow(uint256 repayAmount) external virtual returns (uint256);

  function repayBorrowBehalf(address borrower, uint256 repayAmount) external virtual returns (uint256);

  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    CTokenInterface cTokenCollateral
  ) external virtual returns (uint256);
}

contract CEtherInterface is CErc20Storage {}