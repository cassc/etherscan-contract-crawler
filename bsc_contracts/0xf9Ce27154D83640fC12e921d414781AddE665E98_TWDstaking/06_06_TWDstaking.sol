// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

    error TransferFailed();
    error NotOwner();
    error NeedsMoreThanZero();
    error NeedsNotPaused();
    error MustBeAboveMinimumLockPeriod();

contract TWDstaking is ReentrancyGuard {
    IERC20 public s_rewardsToken;
    IERC20 public s_stakingToken;

    // This is the reward token per second
    // Which will be multiplied by the tokens the user staked divided by the total
    // This ensures a steady reward rate of the platform
    // So the more users stake, the less for everyone who is staking.
    uint256 public reward_rate = 17;
    address public owner;
    uint256 public s_minimumLockDuration = 40 days;
    uint256 public s_lastUpdateTime;
    uint256 public s_rewardPerTokenStored;
    bool public paused;
    uint256 public balance;

    mapping(address => uint256) public s_userRewardPerTokenPaid;
    mapping(address => uint256) public s_rewards;

    uint256 public s_totalSupply;
    mapping(address => uint256) public s_balances;
    mapping(address => uint256) public s_durations;

    event Staked(address indexed user, uint256 indexed amount);
    event WithdrewStake(address indexed user, uint256 indexed amount);
    event RewardsClaimed(address indexed user, uint256 indexed amount);
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);

    constructor(address stakingToken, address rewardsToken) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardsToken = IERC20(rewardsToken);
        owner = msg.sender;
    }

    /********************/
    /* Modifiers Functions */
    /********************/
    modifier updateReward(address account) {
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount) {
        require(amount != 0, "Amount should be greater than zero");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract paused");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier checkMinimumLockDuration() {
        require(block.timestamp >= s_durations[msg.sender] + s_minimumLockDuration, "Must be above minimum lock period");
        _;
    }

    /**
     * Wallet withdrawal functions for admin
     */

    receive() payable external {
        balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }

    function withdrawEth(uint amount, address payable destAddr) external onlyOwner {
        require(amount <= balance, "Insufficient funds");

        destAddr.transfer(amount);
        balance -= amount;
        emit TransferSent(msg.sender, destAddr, amount);
    }

    function transferERC20(IERC20 token, address to, uint256 amount) external onlyOwner {
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(to, amount);
        emit TransferSent(msg.sender, to, amount);
    }

    /**
     * @notice How much reward a token gets based on how long it's been in and during which "snapshots"
     */
    function rewardPerToken() public view returns (uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }
        return
        s_rewardPerTokenStored +
        (((block.timestamp - s_lastUpdateTime) * reward_rate * 1e18) / s_totalSupply);
    }

    /**
     * @notice How much reward a user has earned
     */
    function earned(address account) public view returns (uint256) {
        return
        ((s_balances[account] * (rewardPerToken() - s_userRewardPerTokenPaid[account])) /
        1e18) + s_rewards[account];
    }

    /**
     * @notice Deposit tokens into this contract
     * @param amount | How much to stake
     */
    function stake(uint256 amount)
    external
    notPaused
    moreThanZero(amount)
    updateReward(msg.sender)
    nonReentrant
    {
        s_totalSupply += amount;
        s_balances[msg.sender] += amount;
        if (s_durations[msg.sender] == 0) {
            s_durations[msg.sender] = block.timestamp;
        }
        emit Staked(msg.sender, amount);
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert TransferFailed();
        }
    }

    /**
     * @notice Withdraw tokens from this contract
     * @param amount | How much to withdraw
     */
    function withdraw(uint256 amount) external checkMinimumLockDuration updateReward(msg.sender) nonReentrant {
        s_totalSupply -= amount;
        s_balances[msg.sender] -= amount;
        emit WithdrewStake(msg.sender, amount);
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if (!success) {
            revert TransferFailed();
        }
    }

    /**
     * @notice User claims their tokens
     */
    function claimReward() external updateReward(msg.sender) nonReentrant {
        uint256 reward = s_rewards[msg.sender];
        s_rewards[msg.sender] = 0;
        emit RewardsClaimed(msg.sender, reward);
        bool success = s_rewardsToken.transfer(msg.sender, reward);
        if (!success) {
            revert TransferFailed();
        }
    }

    /********************/
    /* Getter Functions */
    /********************/
    // Ideally, we'd have getter functions for all our s_ variables we want exposed, and set them all to private.
    // But, for the purpose of this demo, we've left them public for simplicity.

    function getStaked(address account) public view returns (uint256) {
        return s_balances[account];
    }
    
    function updateRewardRate(uint256 rate) external onlyOwner {
        reward_rate = rate;
    }

    function updateMinimumLockDuration(uint256 time) external onlyOwner {
        s_minimumLockDuration = time;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

}