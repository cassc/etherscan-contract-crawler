// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IBitXGoldSwap.sol";

/// @title  Staking contract
/// @notice You can use this contract for staking NFTs
/// @dev All function calls are currently implemented without side effects

contract BitXStaking is ReentrancyGuardUpgradeable, OwnableUpgradeable {
  IERC20 public bxg;
  IBitXGoldSwap private pool;
  uint256 itemCount;

  struct StakerStruct {
    address staker;
    uint256 amountStaked;
    uint256 tokensStaked;
    bool referralsAdded;
    bool referralsRewarded;
  }

  struct StakedToken {
    uint256 stakedId;
    uint256 startingTime;
    uint256 rewardsEarned;
    uint256 amountStaked;
  }

  struct Referrals {
    address firstReferral;
    address secondReferral;
    address thirdReferral;
  }

  uint256 miniStakingTime;
  uint256 apy;
  uint256 month;
  uint256 day;
  uint256 reward;

  // Mapping of staker
  mapping(address => StakerStruct) public Staker;
  // Mapping of staker to referrals
  mapping(address => Referrals) public StakedReferrals;
  // Mapping of Staker Address to StakedID to StakedToken
  mapping(address => mapping(uint256 => StakedToken)) public StakedTokens;

  event Stake(address staker, uint256 amountStaked, uint256 stakedId);
  event Claim(address staker, uint256 amountClaimed);
  event ReferralsAwarded(uint256 referralReward1, uint256 referralReward2, uint256 referralReward3);
  event Unstake(address staker, uint256 amountUnstaked);

  /**
   * @dev BitXStaking Upgradable initializer
   * @param _bxg BXG contract address
   * @param _pool BITX SWAP contract address
   */

  function __BitXStaking_init(IERC20 _bxg, IBitXGoldSwap _pool) external initializer {
    __Ownable_init();
    bxg = _bxg;
    pool = _pool;
    miniStakingTime = 2592000;
    month = 2592000;
    day = 86400;
    reward = 3;
  }

  function addReferral(address[] memory _referrals, address staker) external {
    require(StakedReferrals[staker].firstReferral == address(0), "Referrals already added!");
    StakedReferrals[staker].firstReferral = _referrals[0];
    StakedReferrals[staker].secondReferral = _referrals[1];
    StakedReferrals[staker].thirdReferral = _referrals[2];
  }

  // @param _amount The amount of tokens to be staked
  function stake(uint256 _amount) external nonReentrant returns (uint256) {
    // Check amount being staked is atleast 20 BXG
    require((Staker[msg.sender].amountStaked + _amount) >= 20e18, "Amount should be atleast 20 BXG!");
    // Transfer the token from the wallet to the Smart contract
    bxg.transferFrom(msg.sender, address(this), _amount);

    // Create staker if he doesn't exist
    bool referralsAdded = StakedReferrals[msg.sender].firstReferral == address(0) ? false : true;
    if (Staker[msg.sender].staker != msg.sender) {
      Staker[msg.sender] = StakerStruct(msg.sender, _amount, 1, referralsAdded, false);
    } else {
      Staker[msg.sender].amountStaked = Staker[msg.sender].amountStaked + _amount;
      Staker[msg.sender].tokensStaked++;
    }
    // Create StakedToken
    StakedTokens[msg.sender][Staker[msg.sender].tokensStaked] = StakedToken(
      Staker[msg.sender].tokensStaked,
      block.timestamp,
      0,
      _amount
    );

    emit Stake(msg.sender, _amount, Staker[msg.sender].tokensStaked);
    return Staker[msg.sender].tokensStaked;
  }

  // When user tries to retrieve token before minimum time to earn reward has been reached
  // As such they wont earn any rewards
  // @param _amount Amount of token to unstake
  function unStake(uint256 _amount, uint256 _tokensId) external nonReentrant {
    require(
      block.timestamp - StakedTokens[msg.sender][_tokensId].startingTime < miniStakingTime,
      "Your reward is ready, claim it!"
    );
    require(StakedTokens[msg.sender][_tokensId].amountStaked >= _amount, "Amount being unstaked is too much!");

    // Transfer the tokens back
    bxg.transfer(msg.sender, _amount);
    Staker[msg.sender].amountStaked = Staker[msg.sender].amountStaked - _amount;
    StakedTokens[msg.sender][_tokensId].amountStaked = StakedTokens[msg.sender][_tokensId].amountStaked - _amount;
    if (StakedTokens[msg.sender][_tokensId].amountStaked == 0) delete StakedTokens[msg.sender][_tokensId];

    emit Unstake(msg.sender, _amount);
  }

  // @param _amount The amount of reward to withdraw
  function withdraw(uint256 _amount, uint256 _tokensId) external nonReentrant {
    // Check amount staked isn't less than the amount being withdrawed
    require(StakedTokens[msg.sender][_tokensId].amountStaked >= _amount, "Amount being withdrawen is too much!");

    uint256 timeStaked = block.timestamp - StakedTokens[msg.sender][_tokensId].startingTime;
    //Check that it has been atleast three months
    require(timeStaked >= miniStakingTime, "It hasn't been one month since staking");

    uint256 _totalRewards = calculateRewards(_amount, timeStaked);

    // Check if referrals were awarded
    if (!(Staker[msg.sender].referralsRewarded)) {
      awardReferrals(msg.sender, _amount);
      Staker[msg.sender].referralsRewarded = true;
    }

    Staker[msg.sender].amountStaked = Staker[msg.sender].amountStaked - _amount;
    StakedTokens[msg.sender][_tokensId].amountStaked = StakedTokens[msg.sender][_tokensId].amountStaked - _amount;
    if (StakedTokens[msg.sender][_tokensId].amountStaked == 0) delete StakedTokens[msg.sender][_tokensId];
    //Reward Staker
    pool.transferReward(msg.sender, _totalRewards);
    bxg.transfer(msg.sender,_amount);
    emit Claim(msg.sender, _amount);
  }

  // @param _amount The amount being withdrawn
  // @param _timeStaked The starting time of staking
  function calculateRewards(uint256 _amount, uint256 _timeStaked) public view returns (uint256) {
    uint256 _months = _timeStaked / miniStakingTime;
    uint256 _totalPercentage = reward * _months;
    return ((_amount * _totalPercentage) / 100);
  }

  function awardReferrals(address _staker, uint256 _amount) internal {
    uint256 reward1;
    uint256 reward2;
    uint256 reward3;
    if (
      StakedReferrals[_staker].firstReferral != address(0) &&
      StakedReferrals[_staker].secondReferral == address(0) &&
      StakedReferrals[_staker].thirdReferral == address(0)
    ) {
      reward1 = ((_amount * 1) / 100);
      pool.transferReward(StakedReferrals[_staker].firstReferral, reward1);
    }
    // Incase of only two referrals
    else if (
      StakedReferrals[_staker].firstReferral != address(0) &&
      StakedReferrals[_staker].secondReferral != address(0) &&
      StakedReferrals[_staker].thirdReferral == address(0)
    ) {
      reward1 = ((_amount * 7e17) / 100e18);
      reward2 = ((_amount * 3e17) / 100e18);
      pool.transferReward(StakedReferrals[_staker].firstReferral, reward1);
      pool.transferReward(StakedReferrals[_staker].secondReferral, reward2);
      // Incase of three referrals
    } else if (
      StakedReferrals[_staker].firstReferral != address(0) &&
      StakedReferrals[_staker].secondReferral != address(0) &&
      StakedReferrals[_staker].thirdReferral != address(0)
    ) {
      reward1 = ((_amount * 7e17) / 100e18);
      reward2 = ((_amount * 2e17) / 100e18);
      reward3 = ((_amount * 1e17) / 100e18);
      pool.transferReward(StakedReferrals[_staker].firstReferral, reward1);
      pool.transferReward(StakedReferrals[_staker].secondReferral, reward2);
      pool.transferReward(StakedReferrals[_staker].thirdReferral, reward3);
    }
    emit ReferralsAwarded(reward1, reward2, reward3);
  }
}