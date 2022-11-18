// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMajrNFT {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IMajrCanon {
  function paused() external view returns (bool);
}

contract MajrStaking is Ownable, ReentrancyGuard, Pausable {
  /// @notice Address of the reward token (MAJR ERC20 token)
  IERC20 public immutable rewardsToken;

  /// @notice Address of the staking token
  IMajrNFT public immutable stakingToken;

  /// @notice Address of the MAJR Canon (governance) contract
  IMajrCanon public majrCanon;

  /// @notice Tracks the period where users stop earning rewards
  uint256 public periodFinish = 0;

  /// @notice Rewards rate that users are earning
  uint256 public rewardRate = 0;

  /// @notice How long the rewards lasts, it updates when more rewards are added
  uint256 public rewardsDuration = 4383 days; // ~ 12 years, including the leap years of 2024, 2028 & 2032

  /// @notice Last time rewards were updated
  uint256 public lastUpdateTime;

  /// @notice Amount of reward calculated per token stored
  uint256 public rewardPerTokenStored;

  /// @notice Track the rewards paid to users
  mapping(address => uint256) public userRewardPerTokenPaid;

  /// @notice Tracks the user rewards
  mapping(address => uint256) public rewards;

  /// @notice Tracks which user has staked which token Ids
  mapping(address => uint256[]) public userStakedTokenIds;

  /// @dev Tracks the total supply of staked tokens
  uint256 private _totalSupply;

  /// @dev Tracks the amount of staked tokens per user
  mapping(address => uint256) private _balances;

  /// @notice An event emitted when a reward is added
  event RewardAdded(uint256 reward);

  /// @notice An event emitted when a single NFT is staked
  event Stake(address indexed user, uint256 tokenId);

  /// @notice An event emitted when all NFTs from a single transaction are staked by a user
  event StakeTotal(address indexed user, uint256 amount);

  /// @notice An event emitted when a single staked NFT is withdrawn
  event Withdraw(address indexed user, uint256 tokenId);

  /// @notice An event emitted when all staked tokens are withdrawn in a single transaction by a user
  event WithdrawTotal(address indexed user, uint256 amount);

  /// @notice An event emitted when reward is paid to a user
  event RewardPaid(address indexed user, uint256 reward);

  /// @notice An event emitted when the rewards duration is updated
  event RewardsDurationUpdated(uint256 newDuration);

  /**
   * @notice Constructor
   * @param _owner address
   * @param _rewardsToken address
   * @param _stakingToken uint256
   */
  constructor(address _owner, address _rewardsToken, address _stakingToken) {
    rewardsToken = IERC20(_rewardsToken);
    stakingToken = IMajrNFT(_stakingToken);
    transferOwnership(_owner);
  }

  /**
   * @notice Updates the reward and time on call
   * @param _account address
   */
  modifier updateReward(address _account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();

    if (_account != address(0)) {
      rewards[_account] = earned(_account);
      userRewardPerTokenPaid[_account] = rewardPerTokenStored;
    }
    _;
  }

  /** 
   * @notice Returns the total amount of staked tokens
   * @return uint256
  */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @notice Returns the amount of staked tokens from a specific user
   * @param _account address
   * @return uint256
   */
  function balanceOf(address _account) external view returns (uint256) {
    return _balances[_account];
  }

  /**
   * @notice Returns the total amount of tokens to be distributed as a reward
   * @return uint256
   */ 
  function getRewardForDuration() external view returns (uint256) {
    return rewardRate * rewardsDuration;
  }

  /**
   * @notice Returns the IDs of all NFTs that a particular user has staked
   * @param _user address
   * @return uint256[] memory
   */
  function getUserStakedTokenIds(address _user) external view returns (uint256[] memory) {
    return userStakedTokenIds[_user];
  }

  /**
   * @notice Transfers staking tokens (NFTs) to the staking contract
   * @param _tokenIds uint256[] calldata
   * @dev Updates rewards on call
   */
  function stake(uint256[] calldata _tokenIds) external nonReentrant whenNotPaused updateReward(msg.sender)  {
    require(_tokenIds.length > 0, "MajrStaking: Cannot stake 0 tokens.");

    _totalSupply += _tokenIds.length;
    _balances[msg.sender] += _tokenIds.length;

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      userStakedTokenIds[msg.sender].push(_tokenIds[i]);
      stakingToken.transferFrom(msg.sender, address(this), _tokenIds[i]);

      emit Stake(msg.sender, _tokenIds[i]);
    }

    emit StakeTotal(msg.sender, _tokenIds.length);
  }

  /// @notice Removes all stake and transfers all rewards to the staker
  function exit() external {
    withdraw(_balances[msg.sender]);
    getReward();
  }

  /**
   * @notice Notifies the contract that reward has been added to be given
   * @param _reward uint
   * @dev Only owner can call it
   * @dev Increases duration of rewards
   */
  function notifyRewardAmount(uint256 _reward) external onlyOwner updateReward(address(0)) {
    if (block.timestamp >= periodFinish) {
      rewardRate = _reward / rewardsDuration;
    } else {
      uint256 remaining = periodFinish - block.timestamp;
      uint256 leftover = remaining * rewardRate;
      rewardRate = (_reward + leftover) / rewardsDuration;
    }

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 balance = rewardsToken.balanceOf(address(this));
    require(rewardRate <= balance / rewardsDuration, "MajrStaking: Provided reward too high");
    
    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp + rewardsDuration;

    emit RewardAdded(_reward);
  }

  /**
   * @notice Updates the reward duration
   * @param _rewardsDuration uint
   * @dev Only owner can call it
   * @dev Previous rewards must be completed
   */
  function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    require(block.timestamp > periodFinish, "MajrStaking: Previous rewards period must be complete before changing the duration for the new period.");

    rewardsDuration = _rewardsDuration;

    emit RewardsDurationUpdated(rewardsDuration);
  }

  /**
   * @notice Returns the minimum between the current block timestamp or the finish period of rewards
    * @return uint256
   */ 
  function lastTimeRewardApplicable() public view returns (uint256) {
    return min(block.timestamp, periodFinish);
  }

  /**
   * @notice Returns the calculated reward per token deposited
   * @return uint256
   */ 
  function rewardPerToken() public view returns (uint256) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }

    return rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate) / _totalSupply;
  }

  /**
   * @notice Returns the amount of reward tokens a user has earned
   * @param _account address
   * @return uint256
   */
  function earned(address _account) public view returns (uint256) {
    return _balances[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account]) + rewards[_account];
  }

  /**
   * @notice Returns the minimun between two variables
   * @param _a uint
   * @param _b uint
   * @return uint256
   */
  function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }

  /**
   * @notice Removes staking tokens and transfers them back to the staker. Users can only withdraw while the voting in the MAJR Canon (governance) contract is not active
   * @param _amount uint
   * @dev Updates rewards on call
   */
  function withdraw(uint256 _amount) public nonReentrant updateReward(msg.sender) {
    require(_amount > 0, "MajrStaking: Cannot withdraw 0 tokens.");
    require(_amount <= _balances[msg.sender], "MajrStaking: Cannot withdraw more tokens than staked.");
    require(isVotingActive() == false, "MajrStaking: Cannot withdraw staked MAJR IDs while voting is active.");

    _totalSupply = _totalSupply - _amount;
    _balances[msg.sender] = _balances[msg.sender] - _amount;

    for (uint256 i = 0; i < _amount; i++) {
      uint256 tokenId = userStakedTokenIds[msg.sender][userStakedTokenIds[msg.sender].length - 1];

      userStakedTokenIds[msg.sender].pop();
      stakingToken.transferFrom(address(this), msg.sender, tokenId);

      emit Withdraw(msg.sender, tokenId);
    }

    emit WithdrawTotal(msg.sender, _amount);
  }

  /**
   * @notice Transfers the current amount of rewards tokens earned to the caller
   * @dev Updates rewards on call
   */
  function getReward() public nonReentrant updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];

    if (reward > 0) {
      rewards[msg.sender] = 0;

      bool sent = rewardsToken.transfer(msg.sender, reward);
      require(sent, "MajrStaking: ERC20 token transfer failed.");

      emit RewardPaid(msg.sender, reward);
    }
  }

  /**
   * @notice Pauses the pausable functions inside the contract
   * @dev Only owner can call it
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpauses the pausable functions inside the contract
   * @dev Only owner can call it
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Returns whether or not the voting is currently active in the MAJR Canon contract. Voting is considered to be active only if the MAJR Canon contract is not paused
   * @return bool
   */
  function isVotingActive() public view returns (bool) {
    return majrCanon.paused() == false;
  }

  /**
   * @notice Sets the new governance contract (MAJR Canon) address
   * @dev Only owner can call it
   */
  function setMajrCanon(address _majrCanon) external onlyOwner {
    majrCanon = IMajrCanon(_majrCanon);
  }
}