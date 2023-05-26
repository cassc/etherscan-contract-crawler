// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/IDeFiPlazaGov.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DeFi Plaza governance token (DFPgov)
 * @author Jazzer 9F
 * @notice Implements lean on gas liquidity reward program for DeFi Plaza
 */
contract DFPgov is IDeFiPlazaGov, Ownable, ERC20 {

  // global staking contract state parameters squeezed in 256 bits
  struct StakingState {
    uint96 totalStake;                      // Total LP tokens currently staked
    uint96 rewardsAccumulatedPerLP;         // Rewards accumulated per staked LP token (16.80 bits)
    uint32 lastUpdate;                      // Timestamp of last update
    uint32 startTime;                       // Timestamp rewards started
  }

  // data per staker, some bits remaining available
  struct StakeData {
    uint96 stake;                           // Amount of LPs staked for this staker
    uint96 rewardsPerLPAtTimeStaked;        // Baseline rewards at the time these LPs were staked
  }

  address public founder;
  address public multisig;
  address public indexToken;
  StakingState public stakingState;
  mapping(address => StakeData) public stakerData;
  uint256 public multisigAllocationClaimed;
  uint256 public founderAllocationClaimed;

  /**
  * Basic setup
  */
  constructor(address founderAddress, uint256 mintAmount, uint32 startTime) ERC20("Defi Plaza governance", "DFP2") {
    // contains the global state of the staking progress
    StakingState memory state;
    state.startTime = startTime;
    stakingState = state;

    // generate the initial 4M founder allocation
    founder = founderAddress;
    _mint(founderAddress, mintAmount);
  }

  /**
  * For staking LPs to accumulate governance token rewards.
  * Maintains a single stake per user, but allows to add on top of existing stake.
  */
  function stake(uint96 LPamount)
    external
    override
    returns(bool success)
  {
    // Collect LPs
    require(
      IERC20(indexToken).transferFrom(msg.sender, address(this), LPamount),
      "DFP: Transfer failed"
    );

    // Update global staking state
    StakingState memory state = stakingState;
    if ((block.timestamp >= state.startTime) && (state.lastUpdate < 365 days)) {
      uint256 t1 = block.timestamp - state.startTime;       // calculate time relative to start time
      uint256 t0 = uint256(state.lastUpdate);
      t1 = (t1 > 365 days) ? 365 days : t1;                 // clamp at 1 year
      uint256 R1 = 100e24 * t1 / 365 days - 50e24 * t1 * t1 / (365 days)**2;
      uint256 R0 = 100e24 * t0 / 365 days - 50e24 * t0 * t0 / (365 days)**2;
      uint256 totalStake = (state.totalStake < 1600e18) ? 1600e18 : state.totalStake;  // Clamp at 1600 for numerical reasons
      state.rewardsAccumulatedPerLP += uint96(((R1 - R0) << 80) / totalStake);
      state.lastUpdate = uint32(t1);
    }
    state.totalStake += LPamount;
    stakingState = state;

    // Update staker data for this user
    StakeData memory staker = stakerData[msg.sender];
    if (staker.stake == 0) {
      staker.stake = LPamount;
      staker.rewardsPerLPAtTimeStaked = state.rewardsAccumulatedPerLP;
    } else {
      uint256 LP1 = staker.stake + LPamount;
      uint256 RLP0_ = (uint256(LPamount) * state.rewardsAccumulatedPerLP + uint256(staker.stake) * staker.rewardsPerLPAtTimeStaked) / LP1;
      staker.stake = uint96(LP1);
      staker.rewardsPerLPAtTimeStaked = uint96(RLP0_);
    }
    stakerData[msg.sender] = staker;

    // Emit staking event
    emit Staked(msg.sender, LPamount);
    return true;
  }

  /**
  * For unstaking LPs and collecting rewards accumulated up to this point.
  * Any unstake action distributes and resets rewards. Simply claiming rewards
  * without unstaking can be done by unstaking zero LPs.
  */
  function unstake(uint96 LPamount)
    external
    override
    returns(uint256 rewards)
  {
    // Collect data for this user
    StakeData memory staker = stakerData[msg.sender];
    require(
      staker.stake >= LPamount,
      "DFP: Insufficient stake"
    );

    // Update the global staking state
    StakingState memory state = stakingState;
    if ((block.timestamp >= state.startTime) && (state.lastUpdate < 365 days)) {
      uint256 t1 = block.timestamp - state.startTime;       // calculate time relative to start time
      uint256 t0 = uint256(state.lastUpdate);
      t1 = (t1 > 365 days) ? 365 days : t1;                 // clamp at 1 year
      uint256 R1 = 100e24 * t1 / 365 days - 50e24 * t1 * t1 / (365 days)**2;
      uint256 R0 = 100e24 * t0 / 365 days - 50e24 * t0 * t0 / (365 days)**2;
      uint256 totalStake = (state.totalStake < 1600e18) ? 1600e18 : state.totalStake;  // Clamp at 1600 for numerical reasons
      state.rewardsAccumulatedPerLP += uint96(((R1 - R0) << 80) / totalStake);
      state.lastUpdate = uint32(t1);
    }
    state.totalStake -= LPamount;
    stakingState = state;

    // Calculate rewards
    rewards = ((uint256(state.rewardsAccumulatedPerLP) - staker.rewardsPerLPAtTimeStaked) * staker.stake) >> 80;

    // Update user data
    if (LPamount == staker.stake) delete stakerData[msg.sender];
    else {
      staker.stake -= LPamount;
      staker.rewardsPerLPAtTimeStaked = state.rewardsAccumulatedPerLP;
      stakerData[msg.sender] = staker;
    }

    // Distribute reward and emit event
    _mint(msg.sender, rewards);
    require(
      IERC20(indexToken).transfer(msg.sender, LPamount),
      "DFP: Kernel panic"
    );
    emit Unstaked(msg.sender, LPamount, rewards);
  }

  /**
  * Helper function to check unclaimed rewards for any address
  */
  function rewardsQuote(address stakerAddress)
    external
    view
    override
    returns(uint256 rewards)
  {
    // Collect user data
    StakeData memory staker = stakerData[stakerAddress];

    // Calculate distribution since last on chain update
    StakingState memory state = stakingState;
    if ((block.timestamp >= state.startTime) && (state.lastUpdate < 365 days)) {
      uint256 t1 = block.timestamp - state.startTime;       // calculate time relative to start time
      uint256 t0 = uint256(state.lastUpdate);
      t1 = (t1 > 365 days) ? 365 days : t1;                 // clamp at 1 year
      uint256 R1 = 100e24 * t1 / 365 days - 50e24 * t1 * t1 / (365 days)**2;
      uint256 R0 = 100e24 * t0 / 365 days - 50e24 * t0 * t0 / (365 days)**2;
      uint256 totalStake = (state.totalStake < 1600e18) ? 1600e18 : state.totalStake;  // Clamp at 1600 for numerical reasons
      state.rewardsAccumulatedPerLP += uint96(((R1 - R0) << 80) / totalStake);
    }

    // Calculate unclaimed rewards
    rewards = ((uint256(state.rewardsAccumulatedPerLP) - staker.rewardsPerLPAtTimeStaked) * staker.stake) >> 80;
  }

  /**
  * Configure which token is accepted as stake. Can only be done once.
  */
  function setIndexToken(address indexTokenAddress)
    external
    onlyOwner
    returns(bool success)
  {
    require(indexToken==address(0), "Already configured");
    indexToken = indexTokenAddress;
    _mint(indexTokenAddress, 36e23);
    return true;
  }

  /**
  * Set community multisig address
  */
  function setMultisigAddress(address multisigAddress)
    external
    onlyOwner
    returns(bool success)
  {
    multisig = multisigAddress;
    return true;
  }

  /**
  * Community is allocated 5M governance tokens which are released on the same
  * curve as the tokens that users can stake for. No staking required for this.
  * Rewards accumulated can be claimed into the multisig address anytime.
  */
  function claimMultisigAllocation()
    external
    returns(uint256 amountReleased)
  {
    // Collect global staking state
    StakingState memory state = stakingState;
    require(block.timestamp > state.startTime, "Too early guys");

    // Calculate total community allocation until now
    uint256 t1 = block.timestamp - state.startTime;       // calculate time relative to start time
    t1 = (t1 > 365 days) ? 365 days : t1;                 // clamp at 1 year
    uint256 R1 = 5e24 * t1 / 365 days - 25e23 * t1 * t1 / (365 days)**2;

    // Calculate how much is to be released now & update released counter
    amountReleased = R1 - multisigAllocationClaimed;
    multisigAllocationClaimed = R1;

    // Grant rewards and emit event for logging
    _mint(multisig, amountReleased);
    emit MultisigClaim(multisig, amountReleased);
  }

  /**
  * Founder is granted 5M governance tokens after 1 year.
  */
  function claimFounderAllocation(uint256 amount, address destination)
    external
    returns(uint256 actualAmount)
  {
    // Basic validity checks
    require(msg.sender == founder, "Not yours man");
    StakingState memory state = stakingState;
    require(block.timestamp - state.startTime >= 365 days, "Too early man");

    // Calculate how many rewards are still available & update claimed counter
    uint256 availableAmount = 25e23 - founderAllocationClaimed;
    actualAmount = (amount > availableAmount) ? availableAmount : amount;
    founderAllocationClaimed += actualAmount;

    // Grant rewards and emit event for logging
    _mint(destination, actualAmount);
    emit FounderClaim(destination, actualAmount);
  }

  /**
  * Freeze program (makes it easier to migrate if required)
  * This is a one-way thing, only to be used in case of migration.
  */
  function stopProgram()
    external
    onlyOwner()
  {
    // Update the global staking state
    StakingState memory state = stakingState;
    if ((block.timestamp >= state.startTime) && (state.lastUpdate < 365 days)) {
      uint256 t1 = block.timestamp - state.startTime;       // calculate time relative to start time
      uint256 t0 = uint256(state.lastUpdate);
      t1 = (t1 > 365 days) ? 365 days : t1;                 // clamp at 1 year
      uint256 R1 = 100e24 * t1 / 365 days - 50e24 * t1 * t1 / (365 days)**2;
      uint256 R0 = 100e24 * t0 / 365 days - 50e24 * t0 * t0 / (365 days)**2;
      uint256 totalStake = (state.totalStake < 1600e18) ? 1600e18 : state.totalStake;  // Clamp at 1600 for numerical reasons
      state.rewardsAccumulatedPerLP += uint96(((R1 - R0) << 80) / totalStake);
      state.lastUpdate = uint32(t1);
    }

    // Freeze by setting the startTime when we're all going to be dead
    state.startTime = type(uint32).max;
    stakingState = state;
  }
}