// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IClayToken.sol";

/**
    User can stake Sumero LP Tokens (received by providing liquidity to a Liquidity Pool on Sumero) to earn CLAY rewards.
    User can unstake the Sumero LP tokens and claim rewards at any point in time.
    Rewards would depend on your
    - time period of stake  
    - percentage of your staked tokens with respect to total staked tokens

    Owner of this contract can perform following actions:
    - pause / unpause this contract in case of closure of Staking Rewards scheme or other unforseen circumstances
    - change reward rate
 */
contract ClayStakingRewards is Ownable, ReentrancyGuard, Pausable {
    IClayToken public immutable clayToken;
    // Staking token would be Sumero LP tokens
    IERC20 public immutable stakingToken;

    // reward rate i.e. reward in wei rewarded per second for staking a whole token
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public periodFinish; // Contract lifetime.
    uint256 public maxReward; // Max reward that this contract will emit during it's lifetime.

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(
        address _stakedToken,
        address _clayToken,
        uint256 _periodFinish,
        uint256 _maxReward
    ) {
        require(
            _stakedToken != address(0) &&
            _clayToken != address(0),
            "ClayStakingRewards: ZERO_ADDRESS"
        );
        stakingToken = IERC20(_stakedToken);
        clayToken = IClayToken(_clayToken);
        periodFinish = _periodFinish;
        maxReward = _maxReward;
        rewardRate = _maxReward / (_periodFinish - block.timestamp);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastRewardTimeApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    // Gives the rewards calculation till the block.timestamp
    // If the protocol has L(t) tokens staked at time t, then this function returns rewards from time t to block.timestamp
    // i.e, Rewards generated from the time where first ever staking happened in this contract, till now.
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            ((rewardRate *
                (lastRewardTimeApplicable() - lastUpdateTime) *
                1e18) / _totalSupply);
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((_balances[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastRewardTimeApplicable();
        rewards[_account] = earned(_account);
        userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        _;
    }

    modifier notExpired {
        require(
            periodFinish > block.timestamp,
            "ClayStakingRewards: STAKING_PERIOD_EXPIRED"
        );
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 _amount)
        external
        nonReentrant
        whenNotPaused
        notExpired
        updateReward(msg.sender)
    {
        require(_amount > 0, "ClayStakingRewards: AMOUNT_IS_ZERO");
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        bool success = stakingToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(success, "ClayStakingRewards: TRANSFER_FAILED");
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(_amount > 0, "ClayStakingRewards: AMOUNT_IS_ZERO");
        require(
            _amount <= _balances[msg.sender],
            "ClayStakingRewards: INSUFFICIENT_BALANCE"
        );

        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        bool success = stakingToken.transfer(msg.sender, _amount);
        require(success, "ClayStakingRewards: TRANSFER_FAILED");
        emit Withdrawn(msg.sender, _amount);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "ClayStakingRewards: NO_REWARDS");
        rewards[msg.sender] = 0;
        // Sumero Owner needs to grant MINTER_ROLE for CLAY to StakingRewards
        clayToken.mint(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateMaxReward(uint256 _maxReward) external onlyOwner notExpired {
        rewardPerTokenStored = rewardPerToken();
        require(
            ((rewardPerTokenStored * _totalSupply) / 1e18) < _maxReward,
            "ClayStakingRewards: INVALID_MAX_REWARD_AMOUNT"
        );
        lastUpdateTime = block.timestamp;
        maxReward = _maxReward;
        rewardRate =
            (_maxReward - ((rewardPerTokenStored * _totalSupply) / 1e18)) /
            (periodFinish - block.timestamp);
        emit RewardRateUpdated(rewardRate);
    }

    // Added to support recovering LP Rewards from other systems
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(stakingToken),
            "Cannot withdraw the staking token"
        );
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 rewardRate);
    event Recovered(address token, uint256 amount);
}