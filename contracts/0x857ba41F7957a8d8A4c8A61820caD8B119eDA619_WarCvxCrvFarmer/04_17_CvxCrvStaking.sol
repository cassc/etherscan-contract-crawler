pragma solidity 0.8.16;

interface CvxCrvStaking {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Deposited(address indexed _user, address indexed _account, uint256 _amount, bool _isCrv);
  event HookSet(address _rewardToken);
  event IsShutdown();
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event RewardGroupSet(address _rewardToken, uint256 _rewardGroup);
  event RewardInvalidated(address _rewardToken);
  event RewardPaid(address indexed _user, address indexed _token, uint256 _amount, address _receiver);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Withdrawn(address indexed _user, uint256 _amount);

  struct EarnedData {
    address token;
    uint256 amount;
  }

  function addTokenReward(address _token, uint256 _rewardGroup) external;
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function crv() external view returns (address);
  function crvDepositor() external view returns (address);
  function cvx() external view returns (address);
  function cvxCrv() external view returns (address);
  function cvxCrvStaking() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
  function deposit(uint256 _amount, address _to) external;
  function depositAndSetWeight(uint256 _amount, uint256 _weight) external;
  function earned(address _account) external returns (CvxCrvStaking.EarnedData[] memory claimable);
  function getReward(address _account, address _forwardTo) external;
  function getReward(address _account) external;
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
  function invalidateReward(address _token) external;
  function isShutdown() external view returns (bool);
  function name() external view returns (string memory);
  function owner() external view returns (address);
  function reclaim() external;
  function registeredRewards(address) external view returns (uint256);
  function renounceOwnership() external;
  function rewardHook() external view returns (address);
  function rewardLength() external view returns (uint256);
  function rewardSupply(uint256 _rewardGroup) external view returns (uint256);
  function rewards(uint256)
    external
    view
    returns (address reward_token, uint8 reward_group, uint128 reward_integral, uint128 reward_remaining);
  function setApprovals() external;
  function setHook(address _hook) external;
  function setRewardGroup(address _token, uint256 _rewardGroup) external;
  function setRewardWeight(uint256 _weight) external;
  function shutdown() external;
  function stake(uint256 _amount, address _to) external;
  function stakeAndSetWeight(uint256 _amount, uint256 _weight) external;
  function stakeFor(address _to, uint256 _amount) external;
  function supplyWeight() external view returns (uint256);
  function symbol() external view returns (string memory);
  function threeCrv() external view returns (address);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function transferOwnership(address newOwner) external;
  function treasury() external view returns (address);
  function userRewardBalance(address _address, uint256 _rewardGroup) external view returns (uint256);
  function userRewardWeight(address) external view returns (uint256);
  function user_checkpoint(address _account) external returns (bool);
  function withdraw(uint256 _amount) external;
}