pragma solidity 0.8.16;

interface AuraLocker {
  event BlacklistModified(address account, bool blacklisted);
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
  event DelegateCheckpointed(address indexed delegate);
  event KickIncentiveSet(uint256 rate, uint256 delay);
  event KickReward(address indexed _user, address indexed _kicked, uint256 _reward);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event Recovered(address _token, uint256 _amount);
  event RewardAdded(address indexed _token, uint256 _reward);
  event RewardPaid(address indexed _user, address indexed _rewardsToken, uint256 _reward);
  event Shutdown();
  event Staked(address indexed _user, uint256 _paidAmount, uint256 _lockedAmount);
  event Withdrawn(address indexed _user, uint256 _amount, bool _relocked);

  struct DelegateeCheckpoint {
    uint224 votes;
    uint32 epochStart;
  }

  struct EarnedData {
    address token;
    uint256 amount;
  }

  struct LockedBalance {
    uint112 amount;
    uint32 unlockTime;
  }

  function addReward(address _rewardsToken, address _distributor) external;
  function approveRewardDistributor(address _rewardsToken, address _distributor, bool _approved) external;
  function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);
  function balanceOf(address _user) external view returns (uint256 amount);
  function balances(address) external view returns (uint112 locked, uint32 nextUnlockIndex);
  function blacklist(address) external view returns (bool);
  function checkpointEpoch() external;
  function checkpoints(address account, uint32 pos) external view returns (DelegateeCheckpoint memory);
  function claimableRewards(address _account) external view returns (EarnedData[] memory userRewards);
  function cvxCrv() external view returns (address);
  function cvxcrvStaking() external view returns (address);
  function decimals() external view returns (uint8);
  function delegate(address newDelegatee) external;
  function delegateeUnlocks(address, uint256) external view returns (uint256);
  function delegates(address account) external view returns (address);
  function denominator() external view returns (uint256);
  function emergencyWithdraw() external;
  function epochCount() external view returns (uint256);
  function epochs(uint256) external view returns (uint224 supply, uint32 date);
  function findEpochId(uint256 _time) external view returns (uint256 epoch);
  function getPastTotalSupply(uint256 timestamp) external view returns (uint256);
  function getPastVotes(address account, uint256 timestamp) external view returns (uint256 votes);
  function getReward(address _account, bool _stake) external;
  function getReward(address _account) external;
  function getReward(address _account, bool[] memory _skipIdx) external;
  function getVotes(address account) external view returns (uint256);
  function isShutdown() external view returns (bool);
  function kickExpiredLocks(address _account) external;
  function kickRewardEpochDelay() external view returns (uint256);
  function kickRewardPerEpoch() external view returns (uint256);
  function lastTimeRewardApplicable(address _rewardsToken) external view returns (uint256);
  function lock(address _account, uint256 _amount) external;
  function lockDuration() external view returns (uint256);
  function lockedBalances(address _user)
    external
    view
    returns (uint256 total, uint256 unlockable, uint256 locked, LockedBalance[] memory lockData);
  function lockedSupply() external view returns (uint256);
  function modifyBlacklist(address _account, bool _blacklisted) external;
  function name() external view returns (string memory);
  function newRewardRatio() external view returns (uint256);
  function numCheckpoints(address account) external view returns (uint32);
  function owner() external view returns (address);
  function processExpiredLocks(bool _relock) external;
  function queueNewRewards(address _rewardsToken, uint256 _rewards) external;
  function queuedRewards(address) external view returns (uint256);
  function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external;
  function renounceOwnership() external;
  function rewardData(address)
    external
    view
    returns (uint32 periodFinish, uint32 lastUpdateTime, uint96 rewardRate, uint96 rewardPerTokenStored);
  function rewardDistributors(address, address) external view returns (bool);
  function rewardPerToken(address _rewardsToken) external view returns (uint256);
  function rewardTokens(uint256) external view returns (address);
  function rewardsDuration() external view returns (uint256);
  function setApprovals() external;
  function setKickIncentive(uint256 _rate, uint256 _delay) external;
  function shutdown() external;
  function stakingToken() external view returns (address);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256 supply);
  function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);
  function transferOwnership(address newOwner) external;
  function userData(address, address) external view returns (uint128 rewardPerTokenPaid, uint128 rewards);
  function userLocks(address, uint256) external view returns (uint112 amount, uint32 unlockTime);
}