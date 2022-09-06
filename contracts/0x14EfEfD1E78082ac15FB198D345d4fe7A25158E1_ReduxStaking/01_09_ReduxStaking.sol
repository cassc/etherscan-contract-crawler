// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ReduxStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public stakeToken;

    uint256 public duration = 0;
    uint256 private _totalSupply;
    uint256 public periodFinish = 0;
    uint256 public constant REWARD_DENOMINATOR = 10000;
    uint256 public constant SECONDS_IN_YEAR = 365 days;
    uint256 public rewardPeriod = 7 days;
    uint256 public lockUpPeriod = 45 days;
    uint256 public rewardPercent;

    bool public isStakingStarted = false;

    /**
	User Data
	 */
    struct UserData {
        uint256 stakeToken;
        uint256 rewards;
        uint256 lastUpdateTime;
        uint256 stakingTime;
    }

    mapping(address => UserData) public users;
    mapping(address => uint256) public rewardClaimed;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RecoverToken(address indexed token, uint256 indexed amount);
    event StakingStarted(uint256 periodFinish);
    event RewardReInvested(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        if (account != address(0)) {
            users[account].rewards = earned(account);
        }
        users[account].lastUpdateTime = lastTimeRewardApplicable();
        _;
    }

    constructor(
        IERC20 _stakeToken,
        uint256 _duration,
        uint256 _rewardPercent
    ) public {
        stakeToken = _stakeToken;
        duration = _duration;
        rewardPercent = _rewardPercent;
    }

    function getUserData(address addr)
        external
        view
        returns (UserData memory user)
    {
        return users[addr];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function earned(address account) public view returns (uint256) {
        uint256 earnedFromStakeCoin = users[account]
            .stakeToken
            .mul(lastTimeRewardApplicable().sub(users[account].lastUpdateTime))
            .mul(rewardPercent);

        return
            earnedFromStakeCoin
                .div(REWARD_DENOMINATOR)
                .div(SECONDS_IN_YEAR)
                .add(users[account].rewards);
    }

    function stake(uint256 amount) external updateReward(msg.sender) {
        require(isStakingStarted, "Staking is not started yet");
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        users[msg.sender].stakeToken = users[msg.sender].stakeToken.add(amount);
        users[msg.sender].stakingTime = block.timestamp;
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(
            users[msg.sender].stakeToken >= amount,
            "User does not have sufficient balance"
        );
        require(
            users[msg.sender].stakingTime.add(lockUpPeriod) <= block.timestamp,
            "Cannot withdraw before maturity"
        );
        _totalSupply = _totalSupply.sub(amount);
        users[msg.sender].stakeToken = users[msg.sender].stakeToken.sub(amount);
        claimReward();
        stakeToken.safeTransfer(_msgSender(), amount);
        emit Unstaked(msg.sender, amount);
    }

    function compound(address user) external updateReward(user) {
        uint256 reward = users[user].rewards;
        if (reward > 0) {
            users[user].rewards = 0;
            users[user].stakeToken = users[user].stakeToken.add(reward);
            _totalSupply = _totalSupply.add(reward);
            emit RewardReInvested(user, reward);
        }
    }

    function claimReward() public updateReward(msg.sender) {
        require(
            block.timestamp >= rewardClaimed[msg.sender] + rewardPeriod,
            "Can claim reward once 7 days"
        );
        uint256 reward = users[msg.sender].rewards;
        if (reward > 0) {
            rewardClaimed[msg.sender] = block.timestamp;
            users[msg.sender].rewards = 0;
            stakeToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function startStaking() external onlyOwner updateReward(address(0)) {
        require(!isStakingStarted, "Staking is already started");
        isStakingStarted = true;
        periodFinish = block.timestamp.add(duration);
        emit StakingStarted(periodFinish);
    }

    function getNextRewardClaimTime(address account)
        external
        view
        returns (uint256 timestamp)
    {
        return (rewardClaimed[account] + rewardPeriod);
    }

    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
        periodFinish = block.timestamp.add(duration);
    }

    function setRewardPeriod(uint256 _rewardPeriod) external onlyOwner {
        rewardPeriod = _rewardPeriod;
    }

    function setLockUpPeriod(uint256 _lockUpPeriod) external onlyOwner {
        lockUpPeriod = _lockUpPeriod;
    }

    function stopRewardDistribution() external onlyOwner {
        periodFinish = block.timestamp;
    }

    function setRewardPercent(uint256 _rewardPercent) external onlyOwner {
        rewardPercent = _rewardPercent;
    }

    function updateStakeAmountForAirdrop(
        address[] memory beneficiary,
        uint256[] memory stakeAmount
    ) external onlyOwner {
        require(isStakingStarted, "Staking is not started yet");
        require(
            beneficiary.length == stakeAmount.length,
            "Input length invalid"
        );
        uint256 totalStakeAmountForAirdrop;
        for (uint256 i = 0; i < beneficiary.length; i++) {
            _updateStakeAmountForAirdrop(beneficiary[i], stakeAmount[i]);
            totalStakeAmountForAirdrop = totalStakeAmountForAirdrop.add(
                stakeAmount[i]
            );
        }
        _totalSupply = _totalSupply.add(totalStakeAmountForAirdrop);
        stakeToken.safeTransferFrom(
            msg.sender,
            address(this),
            totalStakeAmountForAirdrop
        );
    }

    function _updateStakeAmountForAirdrop(
        address beneficiary,
        uint256 stakeAmount
    ) internal updateReward(beneficiary) {
        users[beneficiary].stakeToken = (users[beneficiary].stakeToken).add(
            stakeAmount
        );
        users[beneficiary].stakingTime = block.timestamp;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function recoverExcessToken(address token, uint256 amount)
        external
        onlyOwner
    {
        IERC20(token).safeTransfer(msg.sender, amount);
        emit RecoverToken(token, amount);
    }
}