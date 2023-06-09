// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ABDK.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

contract Stake is Ownable, Pausable, ReentrancyGuard {
  using ABDKMath64x64 for int128;

  uint256 public lastSavedEpoch;
  uint256 public totalStaked;
  uint256 public START_TIME;
  ERC20 public REWARD_TOKEN;
  ERC20 public STAKING_TOKEN;
  bool public STAKING_SAME_AS_REWARD;

  constructor(address rewardToken, address stakingToken) {
    REWARD_TOKEN = ERC20(rewardToken);
    STAKING_TOKEN = ERC20(stakingToken);
    START_TIME = block.timestamp;
    STAKING_SAME_AS_REWARD = rewardToken == stakingToken;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  uint256 public INTERVAL = 24 hours;

  function updateInterval(uint256 interval) public onlyOwner {
    INTERVAL = interval;
  }

  function getCurrentEpoch() public view returns (uint256) {
    return ((block.timestamp - START_TIME) / (INTERVAL));
  }

  int256 public DELTA_CALC_NUMERATOR = 99;
  int256 public DELTA_CALC_DENOMINATOR = 100;
  int128 public DELTA_CALC_DIVIDED =
    int128(DELTA_CALC_NUMERATOR).divi(DELTA_CALC_DENOMINATOR);

  function updateDeltaCalc(int256 num, int256 denom) public onlyOwner {
    DELTA_CALC_NUMERATOR = num;
    DELTA_CALC_DENOMINATOR = denom;
    DELTA_CALC_DIVIDED = int128(DELTA_CALC_NUMERATOR).divi(
      DELTA_CALC_DENOMINATOR
    );
  }

  function getRewardTokenBalance() public view returns (uint256) {
    uint256 totalBalance = REWARD_TOKEN.balanceOf(address(this));
    return (totalBalance - (STAKING_SAME_AS_REWARD ? totalStaked : 0));
  }

  // Returns 0 decimal precision number
  function _getRewardsForDelta(uint256 delta) internal view returns (uint256) {
    uint256 totalBalance = REWARD_TOKEN.balanceOf(address(this));
    if (totalBalance <= totalStaked && STAKING_SAME_AS_REWARD) {
      return 0;
    }

    uint256 balance = (totalBalance -
      totalRewards -
      (STAKING_SAME_AS_REWARD ? totalStaked : 0)) / 10**18;
    int128 intBalance = ABDKMath64x64.fromUInt(balance);
    int128 b = DELTA_CALC_DIVIDED.pow(delta);
    int128 c = int128(1).fromInt().sub(b);
    int128 d = c.mul(intBalance);
    return d.toUInt();
  }

  function getRewardsForDelta(uint256 delta) public view returns (uint256) {
    return _getRewardsForDelta(delta);
  }

  // Total rewards owed, dynamic number updated as epochs close
  // and when rewards are withdrawn
  uint256 public totalRewards;

  // Sum of all rewards per share for all closed epochs
  uint256 public rewardPerShare;

  function _setEpoch() internal returns (uint256) {
    uint256 epoch = getCurrentEpoch();
    if (lastSavedEpoch < epoch) {
      uint256 delta = epoch - lastSavedEpoch;
      uint256 totalRewardsAtEpoch = _getRewardsForDelta(delta) * 10**18;
      rewardPerShare += totalStaked > 0
        ? PRBMathUD60x18.div(totalRewardsAtEpoch, totalStaked)
        : 0;
      totalRewards += (totalRewardsAtEpoch);
      lastSavedEpoch = epoch;
    }
    return epoch;
  }

  struct Stake {
    bool exists;
    uint256 startEpoch;
    uint256 totalStaked;
    uint256 rewardDebt;
  }

  mapping(address => Stake) public stakes;

  function getTotalStakedByAddress(address staker)
    public
    view
    returns (uint256)
  {
    Stake memory stake = stakes[staker];
    return stake.totalStaked;
  }

  function migrate(address to) public onlyOwner {
    uint256 balance = getRewardTokenBalance();
    REWARD_TOKEN.transfer(to, balance);
  }

  function calcRewards(address staker) public view returns (uint256) {
    uint256 currentEpoch = getCurrentEpoch();
    Stake memory stake = stakes[staker];
    require(stake.exists, "Stake does not exist");

    uint256 totalNotedRewards = totalRewards;

    // If the current epoch is greater than the last saved epoch then
    // we will need to calculate rewards up to current epoch
    if (currentEpoch > lastSavedEpoch) {
      // get additional rewards that have yet to be noted.
      uint256 totalRewardsAtEpoch = _getRewardsForDelta(
        currentEpoch - lastSavedEpoch
      ) * 10**18;

      totalNotedRewards += totalRewardsAtEpoch;

      uint256 projectedRewardPerShare = rewardPerShare +
        (
          totalStaked > 0
            ? PRBMathUD60x18.div(totalRewardsAtEpoch, totalStaked)
            : 0
        );
      return
        PRBMathUD60x18.mul(
          projectedRewardPerShare - stake.rewardDebt,
          stake.totalStaked
        );
    } else {
      return
        PRBMathUD60x18.mul(
          rewardPerShare - stake.rewardDebt,
          stake.totalStaked
        );
    }
  }

  // Function to withdraw all staked, rewards are lost
  function emergencyWithdraw() public nonReentrant {
    _setEpoch();
    require(stakes[msg.sender].exists, "Not staking");
    totalStaked -= stakes[msg.sender].totalStaked;
    STAKING_TOKEN.transfer(msg.sender, stakes[msg.sender].totalStaked);
    delete stakes[msg.sender];
  }

  function withdrawStakedToken(uint256 amount)
    public
    nonReentrant
    whenNotPaused
  {
    uint256 currentEpoch = _setEpoch();

    require(stakes[msg.sender].exists, "Not staking");
    require(
      amount <= stakes[msg.sender].totalStaked,
      "Amount higher than amount staked"
    );
    require(amount > 0, "Amount must be gt 0");
    if (STAKING_SAME_AS_REWARD) {
      _claimAndStakeRewards(currentEpoch);
    } else {
      _claimAndWithdrawRewards(currentEpoch);
    }
    if (amount == stakes[msg.sender].totalStaked) {
      delete stakes[msg.sender];
    } else {
      stakes[msg.sender].startEpoch = currentEpoch + 1;
      stakes[msg.sender].totalStaked -= amount;
      stakes[msg.sender].rewardDebt = rewardPerShare;
    }

    totalStaked -= amount;
    STAKING_TOKEN.transfer(msg.sender, amount);
  }

  function _claimAndWithdrawRewards(uint256 currentEpoch) internal {
    require(stakes[msg.sender].exists, "Not staking");
    uint256 rewards = calcRewards(msg.sender);
    if (rewards > 0) {
      stakes[msg.sender].startEpoch = currentEpoch + 1;
      stakes[msg.sender].rewardDebt = rewardPerShare;
      totalRewards -= rewards;
      REWARD_TOKEN.transfer(msg.sender, rewards);
    }
  }

  function claimAndWithdrawRewards() public nonReentrant whenNotPaused {
    uint256 currentEpoch = _setEpoch();
    _claimAndWithdrawRewards(currentEpoch);
  }

  function _claimAndStakeRewards(uint256 currentEpoch) internal {
    require(
      STAKING_SAME_AS_REWARD,
      "Staking and reward token must be the same to stake rewards"
    );
    require(stakes[msg.sender].exists, "Not staking");
    uint256 rewards = calcRewards(msg.sender);
    if (rewards > 0) {
      stakes[msg.sender].startEpoch = currentEpoch + 1;
      stakes[msg.sender].totalStaked += rewards;
      stakes[msg.sender].rewardDebt = rewardPerShare;
      totalRewards -= rewards;
      totalStaked += rewards;
    }
  }

  function claimAndStakeRewards() public nonReentrant whenNotPaused {
    uint256 currentEpoch = _setEpoch();
    _claimAndStakeRewards(currentEpoch);
  }

  function stake(uint256 amount) public nonReentrant whenNotPaused {
    uint256 currentEpoch = _setEpoch();
    if (stakes[msg.sender].exists == false) {
      stakes[msg.sender] = Stake({
        exists: true,
        startEpoch: currentEpoch + 1,
        totalStaked: amount,
        rewardDebt: rewardPerShare
      });
    } else {
      // If there are rewards to be claimed and the current sender is already staking
      // then we need to determine what to do with the current rewards.

      // If the staking token is same as reward then we can claim and autostake
      if (STAKING_SAME_AS_REWARD) {
        _claimAndStakeRewards(currentEpoch);
      }
      // If the staking token is not the same as the reward token then we can
      // claim and automatically withdraw
      else if (!STAKING_SAME_AS_REWARD) {
        _claimAndWithdrawRewards(currentEpoch);
      }

      stakes[msg.sender].totalStaked += amount;
    }
    totalStaked += amount;
    STAKING_TOKEN.transferFrom(msg.sender, address(this), amount);
  }
}