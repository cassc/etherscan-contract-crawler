// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract LPTokenWrapper is Context {
    using SafeERC20 for IERC20;

    IERC20 private immutable _stakeToken;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(IERC20 __stakeToken) {
        _stakeToken = __stakeToken;
    }

    function stakeToken() public view returns (IERC20) {
        return _stakeToken;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply += amount;
        _balances[_msgSender()] += amount;
        _stakeToken.safeTransferFrom(_msgSender(), address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply -= amount;
        _balances[_msgSender()] -= amount;
        _stakeToken.safeTransfer(_msgSender(), amount);
    }
}

contract Staking is LPTokenWrapper, AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Hash for the distributor role type
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    /// @notice Hash for the pauser role type
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IERC20 public rewardsToken;
    uint256 public duration;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    /* ========== MODIFIERS ========== */

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    /// @param _stakeToken contract address of staking token
    /// @param _rewardsToken contract address of rewards token
    constructor(IERC20 _stakeToken, IERC20 _rewardsToken)
        LPTokenWrapper(_stakeToken)
    {
        rewardsToken = _rewardsToken;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /* ========== FUNCTIONS ========== */

    /// @notice Returns the reward applicable time
    /// @dev Notice that the time cannot be greater than `periodFinish`, i.e. the time at which
    /// the `rewardRate` was set plus the duration.
    /// @return The reward applicable time
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @notice Returns reward amount to be distributed per unit time
    /// @return The reward per token
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) /
            totalSupply();
    }

    /// @notice Returns the reward earned for each user
    /// @param _account The address of the user
    /// @return The rewards earned for each user
    function earned(address _account) public view returns (uint256) {
        return ((balanceOf(_account) *
            (rewardPerToken() - userRewardPerTokenPaid[_account])) /
            1e18 +
            rewards[_account]);
    }

    /// @notice Stakes the given amount in this contract
    /// @param _amount The amount of tokens to be staked
    function stake(uint256 _amount)
        public
        override
        whenNotPaused
        updateReward(_msgSender())
        nonReentrant
    {
        require(_amount > 0, "Cannot stake 0 token");
        super.stake(_amount);
        emit Staked(_msgSender(), _amount);
    }

    /// @notice Withdraws staked tokens from this contract
    /// @param _amount The amount of tokens to be withdrawn
    function withdraw(uint256 _amount)
        public
        override
        whenNotPaused
        updateReward(_msgSender())
        nonReentrant
    {
        require(_amount > 0, "Cannot withdraw 0 token");
        super.withdraw(_amount);
        emit Withdrawn(_msgSender(), _amount);
    }

    /// @notice Exits, i.e. withdraws all rewards and staked tokens in a single transaction
    function exit() external whenNotPaused {
        withdraw(balanceOf(_msgSender()));
        getReward();
    }

    /// @notice Withdraws all rewards earned
    function getReward()
        public
        whenNotPaused
        updateReward(_msgSender())
        nonReentrant
    {
        uint256 reward = earned(_msgSender());
        if (reward > 0) {
            rewards[_msgSender()] = 0;
            rewardsToken.safeTransfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Sets new duration
    /// @dev This function is restricted to the distributor role
    /// @param durationSeconds The duration in units of seconds
    function setNewDuration(uint256 durationSeconds)
        external
        onlyRole(DISTRIBUTOR_ROLE)
    {
        require(durationSeconds > 0, "Duration cannot be zero");
        duration = durationSeconds * 1 seconds;
    }

    /// @notice Sets the token amount to be distributed
    /// @dev This function is restricted to the distributor role
    /// @param reward The token amount to be distributed
    function notifyRewardAmount(uint256 reward)
        external
        onlyRole(DISTRIBUTOR_ROLE)
        updateReward(address(0))
    {
        require(duration != 0, "Duration cannot be zero");

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / duration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / duration;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.

        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance / duration,
            "Reward amount exceeds contract balance"
        );
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;
        emit RewardAdded(reward);
    }

    /// @notice Pauses the execution of pausable functions
    /// @dev This function is restricted to the pauser role
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses the execution of pausable functions
    /// @dev This function is restricted to the pauser role
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}