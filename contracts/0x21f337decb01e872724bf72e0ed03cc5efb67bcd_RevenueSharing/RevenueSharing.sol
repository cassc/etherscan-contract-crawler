/**
 *Submitted for verification at Etherscan.io on 2023-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/**
 * @title RevenueSharing
 * @dev Depositing revenue defines an epoch. Each epoch creates a
 * snapshot of what the rewards are per staked token for that
 * epoch. Each stakeholder tracks the snapshot from which their
 * rewards are accumulated, and keeps this up to date as they claim
 * and adjust their staked balance. Stakeholder rewards are
 * accumulated for each epoch, and can be claimed in O(1) time.
 */
contract RevenueSharing {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    mapping(address => uint) public staked;
    mapping(address => uint) public lastStakeTime;
    uint public totalStaked;

    uint private constant MULTIPLIER = 1e18;
    uint private rewardIndex;
    mapping(address => uint) private rewardIndexOf;
    mapping(address => uint) private earned;

    // How much time must pass before we can withdraw
    uint public unstakeCooldown;

    // All revenue deposited to the contract.
    uint lifetimeRevenue;

    constructor(address _stakingToken, address _rewardToken, uint256 _unstakeCooldown) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        unstakeCooldown = _unstakeCooldown;
    }

    function depositRevenue(uint reward) external {
        require(totalStaked > 0, "can't deposit without anything staked");
        require(reward > 0, "can't deposit 0");
        require(rewardToken.allowance(msg.sender, address(this)) >= reward, "not enough allowance");
        bool isSent = rewardToken.transferFrom(msg.sender, address(this), reward);
        require(isSent, "transfer failed");
        rewardIndex += (reward * MULTIPLIER) / totalStaked;

        lifetimeRevenue += reward;
    }

    function _calculateRewards(address account) private view returns (uint) {
        uint shares = staked[account];
        return (shares * (rewardIndex - rewardIndexOf[account])) / MULTIPLIER;
    }

    function calculateRewardsEarned(address account) external view returns (uint) {
        return earned[account] + _calculateRewards(account);
    }

    function _updateRewards(address account) private {
        earned[account] += _calculateRewards(account);
        rewardIndexOf[account] = rewardIndex;
    }

    function stake(uint amount) external {
        require(amount > 0, "can't stake 0");

        _updateRewards(msg.sender);

        staked[msg.sender] += amount;
        totalStaked += amount;

        require(stakingToken.allowance(msg.sender, address(this)) >= amount, "not enough allowance");
        bool isSent = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(isSent, "transfer failed");

        lastStakeTime[msg.sender] = block.timestamp;
    }

    function unstake(uint amount) external {
        require(block.timestamp - lastStakeTime[msg.sender] > unstakeCooldown, "can't unstake yet");
        require(amount > 0, "can't unstake 0");
        require(amount <= staked[msg.sender], "amount exceeds staked balance");

        _updateRewards(msg.sender);

        staked[msg.sender] -= amount;
        totalStaked -= amount;

        bool isSent = stakingToken.transfer(msg.sender, amount);
        require(isSent, "transfer failed");
    }

    function claim() external returns (uint) {
        _updateRewards(msg.sender);

        uint reward = earned[msg.sender];
        if (reward > 0) {
            earned[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
        }

        return reward;
    }
}