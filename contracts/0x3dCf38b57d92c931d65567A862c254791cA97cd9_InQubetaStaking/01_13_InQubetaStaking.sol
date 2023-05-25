// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IFeeDistribution.sol";

contract InQubetaStaking is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /// @notice Access Control fee distribution contract role hash
    bytes32 public constant FEE_DISTRIBUTION_ROLE =
        keccak256("FEE_DISTRIBUTION_ROLE");
    /// @notice An ERC20 token that is paid out as a reward
    IERC20 public immutable rewardsToken;
    /// @notice ERC20 token that is accepted as a stake
    IERC20 public immutable stakingToken;
    /// @notice timestamp of the end of the reward period
    uint256 public periodFinish;
    /// @notice rewards rate
    uint256 public rewardRate;
    /// @notice the duration of the reward period
    uint256 public rewardsDuration;
    /// @notice timestamp of the last reward update
    uint256 public lastUpdateTime;
    /// @notice reward per token stored
    uint256 public rewardPerTokenStored;
    /// @notice reward distribution contract address
    address public immutable rewardsDistribution;
    /// @notice user rewards per token paid
    mapping(address => uint256) public userRewardPerTokenPaid;
    /// @notice number of user rewards
    mapping(address => uint256) public rewards;
    /// @notice total staked tokens
    uint256 public totalSupply;
    /// @notice user total staked tokens
    mapping(address => uint256) public balanceOf;

    /// ================================ Errors ================================ ///

    ///@dev returned if passed zero amount
    error ZeroAmount(string err);
    ///@dev returned if passed zero address
    error ZeroAddress(string err);
    /// @dev - returned if access is denied
    error AccessIsDenied(string err);
    /// @dev - returned if rewards period not ended
    error NotEnded(string err);
    /// @dev - returned if address is not a contract;
    error NotContract(string err);
    /// @dev - returned if value already assigned
    error AlreadyAssigned(string err);
    /// @dev - returned if token not allowed for recover
    error Recover(string err);

    /// ================================ Events ================================ ///

    ///@dev emitted when fee distribution contract add new rewards
    event RewardAdded(uint256 reward);
    ///@dev emitted when the user makes stake
    event Staked(address indexed user, uint256 amount);
    ///@dev emitted when the user makes withdraw
    event Withdrawn(address indexed user, uint256 amount);
    ///@dev emitted when the user makes get reward
    event RewardPaid(address indexed user, uint256 reward);
    ///@dev emitted when the admin updates the duration of the reward period
    event RewardsDurationUpdated(uint256 indexed newDuration);
    ///@dev emitted when the admin recovers tokens from staking contract
    event Recovered(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );
    ///@dev emitted when the admin updates rewards distribution contract
    event UpdateRewardsDistribution(address indexed newContract);
    event UpdateAdmin(address indexed oldAdmin, address indexed newAdmin);

    constructor(
        address _rewardsDistribution, /// reward distribution contract address
        address _rewardsToken, /// An ERC20 token that is paid out as a reward
        address _stakingToken, /// ERC20 token that is accepted as a stake
        address _admin /// Contract admin
    ) {
        if (
            !Address.isContract(_rewardsToken) ||
            !Address.isContract(_stakingToken) ||
            !Address.isContract(_rewardsDistribution)
        ) {
            revert NotContract("Staking: Address not a contract");
        }
        if (_admin == address(0)) {
            revert ZeroAddress("Staking: Zero address");
        }
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = 7 days;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(FEE_DISTRIBUTION_ROLE, _rewardsDistribution);
    }

    /// ================================ Modifiers ================================ ///

    /**
    @dev the modifier updates account information about rewards
    */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /// ================================ External functions ================================ ///

    /**
     * @notice The function stake the given number of tokens in staking
     * @param amount - stake amount
     */
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        _stake(msg.sender, amount);
    }

    /**
     * @notice The function stake the given number of tokens in staking.
     * Stake is credited to the address passed to the function.
     * @param user - staker address
     * @param amount - stake amount
     */
    function stakeFor(
        address user,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        _stake(user, amount);
    }

    /**
     * @notice The function performs withdrawal of stakes from the contract.
     * @param amount - withdraw amount
     */
    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        _withdraw(msg.sender, amount);
        _replenishRewards();
    }

    /**
     * @notice The function performs the receipt of rewards by the staker
     */
    function claimReward() external nonReentrant whenNotPaused {
        _claimReward(msg.sender);
        _replenishRewards();
    }

    /**
     * @notice The function performs a full exit from staking. Withdrawing the body
     * of the deposit and receiving all available rewards
     */
    function exit() external whenNotPaused nonReentrant {
        _withdraw(msg.sender, balanceOf[msg.sender]);
        _claimReward(msg.sender);
        _replenishRewards();
    }

    /**
     * @notice The function updates all the necessary information for the distribution
     * of rewards between users. Called after the fee distribution contract sends new
     * rewards. Only fee distribution contract can call
     * @param reward - rewards amount
     */
    function notifyRewardAmount(
        uint256 reward
    ) external onlyRole(FEE_DISTRIBUTION_ROLE) updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        emit RewardAdded(reward);
    }

    /**
     * @notice The function performs the withdrawal of ERC20 tokens
     * from the contract. Only the admin can call it
     * @param tokenAddress - ERC20 token address
     * @param tokenAmount - withdraw amount
     * @param recipient - recipient address
     */
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount,
        address recipient
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (recipient == address(0) || tokenAddress == address(0)) {
            revert ZeroAddress("Staking: Zero address");
        }
        if (tokenAmount == 0) {
            revert ZeroAmount("Staking: Zero amount");
        }
        if (
            tokenAddress == address(stakingToken) ||
            tokenAddress == address(rewardsToken)
        ) {
            revert Recover("Staking: Not allowed for recover");
        }
        IERC20(tokenAddress).safeTransfer(recipient, tokenAmount);
        emit Recovered(tokenAddress, recipient, tokenAmount);
    }

    /**
     * @notice The function updates the duration of the rewards period.
     * Can be called after the previous period has ended. Only the admin can call
     * @param _rewardsDuration - new rewards duration
     */
    function setRewardsDuration(
        uint256 _rewardsDuration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (block.timestamp < periodFinish) {
            revert NotEnded("Staking: Previous period should ended");
        }
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /**
     * @notice The function updates the default admin. Removes access from the previous admin and grants it to the new one.
     * If you want to have two or more admins, use the method grantRole.
     * Only the admin can call
     * @param newAdmin - new default admin address
     */
    function updateAdmin(
        address newAdmin
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newAdmin == address(0)) {
            revert ZeroAddress("Staking: Zero address");
        }
        if (newAdmin == msg.sender) {
            revert AlreadyAssigned("Staking: value already assigned");
        }
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        emit UpdateAdmin(msg.sender, newAdmin);
    }

    /// ================================ View functions ================================ ///

    /**
     * @notice View function returns the timestamp at which the distribution of
     * rewards is currently located
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
     * @notice The View function returns the number of rewards that can be received
     * for one token sent to staking
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            ((((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate) *
                1e18) / totalSupply);
    }

    /**
     * @notice View function calculates the rewards earned by the user and returns them
     * @param account - user wallet address
     */
    function earned(address account) public view returns (uint256) {
        return
            (balanceOf[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) /
            1e18 +
            rewards[account];
    }

    /**
     * @notice The function returns the number of rewards that will be distributed
     * before the end of the period
     */
    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    /// ================================ Internal functions ================================ ///

    /**
     * @notice internal function that executes the logic of processing the user's stake.
     *  Updates all user data and writes them to the contract.
     * @param user - staker wallet address
     * @param amount - stake amount
     */
    function _stake(address user, uint256 amount) internal updateReward(user) {
        if (amount == 0) {
            revert ZeroAmount("Staking: Zero amount");
        }
        if (user == address(0)) {
            revert ZeroAddress("Staking: Zero address");
        }
        totalSupply += amount;
        balanceOf[user] += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        _replenishRewards();
        emit Staked(user, amount);
    }

    /**
     * @notice the internal function that performs the logic of withdrawing the
     * body of the deposit.
     *  Updates all user data and writes them to the contract.
     * @param user - staker wallet address
     * @param amount - stake amount
     */
    function _withdraw(
        address user,
        uint256 amount
    ) internal updateReward(user) {
        if (amount == 0) {
            revert ZeroAmount("Staking: Zero amount");
        }
        totalSupply -= amount;
        balanceOf[user] -= amount;
        stakingToken.safeTransfer(user, amount);
        emit Withdrawn(user, amount);
    }

    /**
     * @notice the internal function that performs the logic of claiming the
     * user rewards.
     *  Updates all user data and writes them to the contract.
     * @param user - staker wallet address
     */
    function _claimReward(address user) internal updateReward(user) {
        uint256 reward = rewards[user];
        if (reward > 0) {
            rewards[user] = 0;
            rewardsToken.safeTransfer(user, reward);
            emit RewardPaid(user, reward);
        }
    }

    /**
     * @notice Internal function that replenishes the contract with rewards
     */
    function _replenishRewards() internal {
        IFeeDistribution(rewardsDistribution).distributeIfNeeded();
    }
}