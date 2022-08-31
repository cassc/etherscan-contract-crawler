// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './base/BaseStrategy.sol';

import '../interfaces/maple/IPool.sol';
import '../interfaces/maple/IMplRewards.sol';

// This contract contains logic for depositing staker funds into maple finance as a yield strategy
// https://github.com/maple-labs/maple-core/blob/main/contracts/Pool.sol
// https://github.com/maple-labs/maple-core/wiki/Pools

contract MapleStrategy is BaseStrategy {
  using SafeERC20 for IERC20;
  // MPL Reward contract  0x7C57bF654Bc16B0C9080F4F75FF62876f50B8259
  // Current Maven11 USDC pool: 0x6F6c8013f639979C84b756C7FC1500eB5aF18Dc4
  // https://app.maple.finance/#/earn/pool/0x6f6c8013f639979c84b756c7fc1500eb5af18dc4

  // MPL Reward contract 0x7869D7a3B074b5fa484dc04798E254c9C06A5e90
  // Current Orthogonal Trading  USDC pool: 0xFeBd6F15Df3B73DC4307B1d7E65D46413e710C27
  // https://app.maple.finance/#/earn/pool/0xfebd6f15df3b73dc4307b1d7e65d46413e710c27
  IPool public immutable maplePool;
  IMplRewards public immutable mapleRewards;

  // Address to receive rewards
  address public constant LIQUIDITY_MINING_RECEIVER = 0x666B8EbFbF4D5f0CE56962a25635CfF563F13161;

  /// @param _initialParent Contract that will be the parent in the tree structure
  /// @param _mapleRewards Maple rewards contract linked to USDC staking pool
  constructor(IMaster _initialParent, IMplRewards _mapleRewards) BaseNode(_initialParent) {
    // Get Maple Pool based on the reward pool
    // Store maple pool for future usage
    maplePool = IPool(_mapleRewards.stakingToken());

    // revert if the pool isn't USDC
    if (_initialParent.want() != maplePool.liquidityAsset()) revert InvalidArg();
    // revert if the pool isn't public
    if (maplePool.openToPublic() == false) revert InvalidState();

    // Approve maple mool max amount of USDC
    want.safeIncreaseAllowance(address(maplePool), type(uint256).max);

    // Store maple rewards for future usage
    mapleRewards = _mapleRewards;
  }

  /// @notice Signal if strategy is ready to be used
  /// @return Boolean indicating if strategy is ready
  function setupCompleted() external view override returns (bool) {
    return true;
  }

  /// @notice View timestamp the deposit matures
  /// @dev After this timestamp admin is able to call `withdraw()` if this contract is in the unstake window
  /// @dev Step 1: call `intendToWithdraw()` on `maturityTime` - `stakerCooldownPeriod`
  /// @dev Step 2: when `maturityTime` is reached, the contract is in the unstake window, call `withdraw()` to unstake USDC
  /// @dev https://etherscan.io/address/0xc234c62c8c09687dff0d9047e40042cd166f3600#readContract
  /// @dev stakerCooldownPeriod uint256 :  864000 (10 days to cooldown)
  /// @dev stakerUnstakeWindow  uint256 :  172800 (2 days to unstake)
  function maturityTime() external view returns (uint256) {
    // Get current deposit date from the maple pool
    // Value uses a weigthed average on multiple deposits
    uint256 date = maplePool.depositDate(address(this));

    // Return 0 if no USDC is deposited into the Maple pool
    if (date == 0) return 0;

    // Deposit will mature when lockup period ends
    return date + maplePool.lockupPeriod();
  }

  /// @notice Deposit all USDC in this contract in Maple
  /// @notice Works under the assumption this contract contains USDC
  /// @dev Weighted average is used for depositDate calculation
  /// @dev https://github.com/maple-labs/maple-core/blob/main/contracts/Pool.sol#L377
  /// @dev Multiple deposits = weighted average of unlock time https://github.com/maple-labs/maple-core/blob/main/contracts/library/PoolLib.sol#L209
  function _deposit() internal override whenNotPaused {
    // How many maplePool tokens do we currently own
    uint256 maplePoolBalanceBefore = maplePool.balanceOf(address(this));

    // Deposit all USDC into maple
    maplePool.deposit(want.balanceOf(address(this)));

    // How many maplePool tokens did we gain after depositing
    uint256 maplePoolDifference = maplePool.balanceOf(address(this)) - maplePoolBalanceBefore;

    if (maplePoolDifference == 0) return;

    // Approve newly gained maple pool tokens to mapleRewards
    maplePool.increaseCustodyAllowance(address(mapleRewards), maplePoolDifference);

    // "Stake" new tokens in the mapleRewards pool
    // Note that maple pool tokens are not actually transferred
    // https://github.com/maple-labs/mpl-rewards/blob/main/contracts/MplRewards.sol#L87
    mapleRewards.stake(maplePoolDifference);
  }

  /// @notice Send all USDC in this contract to core
  /// @notice Funds need to be withdrawn using `withdrawFromMaple()` first
  /// @return amount Amount of USDC withdrawn
  function _withdrawAll() internal override returns (uint256 amount) {
    // Amount of USDC in the contract
    amount = want.balanceOf(address(this));
    // Transfer USDC to core
    if (amount != 0) want.safeTransfer(core, amount);
  }

  /// @notice Send `_amount` USDC in this contract to core
  /// @notice Funds need to be withdrawn using `withdrawFromMaple()` first
  /// @param _amount Amount of USDC to withdraw
  function _withdraw(uint256 _amount) internal override {
    // Transfer USDC to core
    want.safeTransfer(core, _amount);
  }

  /// @notice View USDC in this contract + USDC in Maple
  /// @dev Important the balance is only increasing after a `claim()` call by the pool admin
  /// @dev This means people can get anticipate these `claim()` calls and get a better entry/exit position in the Sherlock pool
  /// @return Amount of USDC in this strategy
  // Ideally `withdrawableFundsOf` would be incrementing every block
  // This value mostly depends on `accumulativeFundsOf` https://github.com/maple-labs/maple-core/blob/main/contracts/token/BasicFDT.sol#L70
  // Where `pointsPerShare` is the main variable used to increase balance https://github.com/maple-labs/maple-core/blob/main/contracts/token/BasicFDT.sol#L92
  // This variable is mutated in the internal `_distributeFunds` function https://github.com/maple-labs/maple-core/blob/main/contracts/token/BasicFDT.sol#L47
  // This internal function is called by the public `updateFundsReceived()` which depends on `_updateFundsTokenBalance()` to be > 0 https://github.com/maple-labs/maple-core/blob/main/contracts/token/BasicFDT.sol#L179
  // This can only be >0 if `interestSum` mutates to a bigger value https://github.com/maple-labs/maple-core/blob/main/contracts/token/PoolFDT.sol#L51
  // The place where `interestSum` is mutated is the `claim()` function restricted by pool admin / delegate https://github.com/maple-labs/maple-core/blob/main/contracts/Pool.sol#L222
  function _balanceOf() internal view override returns (uint256) {
    // Source Lucas Manuel | Maple
    // Even though we 'stake' maple pool tokens in the reward contract
    // They are actually not transferred to the reward contract
    // Maple uses custom 'custody' logic in the staking contract
    // https://github.com/maple-labs/mpl-rewards/blob/main/contracts/MplRewards.sol#L92
    return
      want.balanceOf(address(this)) +
      ((maplePool.balanceOf(address(this)) +
        maplePool.withdrawableFundsOf(address(this)) -
        maplePool.recognizableLossesOf(address(this))) / 10**12);
  }

  /// @notice Start cooldown period for Maple withdrawal
  /// @dev Can only be called by owner
  function intendToWithdraw() external onlyOwner {
    // https://github.com/maple-labs/maple-core/blob/main/contracts/Pool.sol#L398
    maplePool.intendToWithdraw();
  }

  /// @notice Withdraw funds to this contract
  /// @dev Can only be called by owner
  /// @notice Actual USDC amount can be bigger or greater based on losses or gains
  /// @notice If `_maplePoolTokenAmount` == `maplePool.balanceOf(address(this)` it will withdraw the max amount of USDC
  /// @notice If `_maplePoolTokenAmount` < `recognizableLossesOf(this)` the transaction will revert
  /// @notice If `_maplePoolTokenAmount` = `recognizableLossesOf(this)`, it will send `withdrawableFundsOf` USDC
  /// @param _maplePoolTokenAmount Amount of maple pool tokens to withdraw (usdc * 10**12)
  function withdrawFromMaple(uint256 _maplePoolTokenAmount) external onlyOwner {
    // Exiting 0 tokens doesn't make sense
    if (_maplePoolTokenAmount == 0) revert ZeroArg();

    // Withdraw all USDC
    if (_maplePoolTokenAmount == type(uint256).max) {
      // Withdraw all maple pool tokens
      _maplePoolTokenAmount = maplePool.balanceOf(address(this));

      // Exiting 0 tokens doesn't make sense
      if (_maplePoolTokenAmount == 0) revert InvalidState();
    }

    // 'Withdraw' maplePool tokens from maple rewards
    // note that maple pool tokens are not actually transferred
    // https://github.com/maple-labs/mpl-rewards/blob/main/contracts/MplRewards.sol#L98
    mapleRewards.withdraw(_maplePoolTokenAmount);

    // Maple pool = 18 decimals
    // USDC = 6 decimals
    // Exchange rate is 1:1
    // Divide by 10**12 to get USDC amount
    uint256 usdcAmount = _maplePoolTokenAmount / 10**12;

    // On withdraw this function is used for the `withdrawableFundsOf()` https://github.com/maple-labs/maple-core/blob/main/contracts/Pool.sol#L438
    // As it's calling `_prepareWithdraw()` https://github.com/maple-labs/maple-core/blob/main/contracts/Pool.sol#L472
    // Which is using the `withdrawableFundsOf()` function https://github.com/maple-labs/maple-core/blob/main/contracts/token/BasicFDT.sol#L58
    // These earned funds ar send to this contract https://github.com/maple-labs/maple-core/blob/main/contracts/Pool.sol#L476
    // It will automatically add USDC gains and subtract USDC losses.
    // It sends USDC to this contract
    maplePool.withdraw(usdcAmount);
  }

  /// @notice Claim Maple tokens earned by farming
  /// @dev Maple tokens will be send to LIQUIDITY_MINING_RECEIVER
  function claimReward() external {
    // Claim reward tokens
    mapleRewards.getReward();

    // Cache reward token address
    IERC20 rewardToken = mapleRewards.rewardsToken();

    // Query reward token balance
    uint256 balance = rewardToken.balanceOf(address(this));

    // Send all reward tokens to LIQUIDITY_MINING_RECEIVER
    if (balance != 0) rewardToken.safeTransfer(LIQUIDITY_MINING_RECEIVER, balance);
  }
}