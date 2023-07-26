pragma solidity ^0.5.16;

import "./Math.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract LPStakingRewards is Ownable, ReentrancyGuard {
    using KineSafeMath for uint;
    using SafeERC20 for IERC20;

    event NewRewardDistribution(address oldRewardDistribution, address newRewardDistribution);
    event NewRewardDuration(uint oldRewardDuration, uint newRewardDuration);
    event NewRewardReleasePeriod(uint oldRewardReleasePeriod, uint newRewardReleasePeriod);
    event NewCooldownTime(uint oldCooldownTime, uint newCooldownTime);
    event Staked(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RewardAdded(uint reward);
    event RewardPaid(address indexed user, uint reward);

    /**
     * @notice This is for avoiding reward calculation overflow (see https://sips.synthetix.io/sips/sip-77)
     * 1.15792e59 < uint(-1) / 1e18
    */
    uint public constant REWARD_OVERFLOW_CHECK = 1.15792e59;

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    address public rewardDistribution;
    uint public rewardDuration;
    uint public rewardReleasePeriod;
    uint public startTime;
    uint public periodFinish = 0;
    uint public rewardRate = 0;
    uint public rewardPerTokenStored;
    uint public lastUpdateTime;
    uint public claimCooldownTime;
    uint public totalStakes = 0;

    struct AccountRewardDetail {
        uint lastClaimTime;
        uint rewardPerTokenUpdated;
        uint accruedReward;
    }

    mapping(address => AccountRewardDetail) public accountRewardDetails;
    mapping(address => uint) public accountStakes;

    constructor (address rewardsToken_, address stakingToken_, uint startTime_) public {
        rewardsToken = IERC20(rewardsToken_);
        stakingToken = IERC20(stakingToken_);
        startTime = startTime_;
    }

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    modifier checkStart() {
        require(block.timestamp >= startTime, "not started yet");
        _;
    }

    modifier afterCooldown(address staker) {
        require(accountRewardDetails[staker].lastClaimTime.add(claimCooldownTime) < block.timestamp, "claim cooling down");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            AccountRewardDetail storage rd = accountRewardDetails[account];
            rd.accruedReward = earned(account);
            rd.rewardPerTokenUpdated = rewardPerTokenStored;
            if (rd.lastClaimTime == 0) {
                rd.lastClaimTime = block.timestamp;
            }
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalStakes == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalStakes)
        );
    }

    function earned(address account) public view returns (uint) {
        return accountStakes[account]
        .mul(rewardPerToken().sub(accountRewardDetails[account].rewardPerTokenUpdated))
        .div(1e18)
        .add(accountRewardDetails[account].accruedReward);
    }

    function claimable(address account) external view returns (uint) {
        uint accountNewAccruedReward = earned(account);
        uint pastTime = block.timestamp.sub(accountRewardDetails[account].lastClaimTime);
        uint maturedReward = rewardReleasePeriod == 0 ? accountNewAccruedReward : accountNewAccruedReward.mul(pastTime).div(rewardReleasePeriod);
        if (maturedReward > accountNewAccruedReward) {
            maturedReward = accountNewAccruedReward;
        }
        return maturedReward;
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardDuration);
    }

    function stake(uint256 amount) external nonReentrant checkStart updateReward(msg.sender) {
        require(amount > 0, "staking 0");
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        totalStakes = totalStakes.add(amount);
        accountStakes[msg.sender] = accountStakes[msg.sender].add(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "withdrawing 0");
        totalStakes = totalStakes.sub(amount);
        accountStakes[msg.sender] = accountStakes[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant afterCooldown(msg.sender) updateReward(msg.sender) {
        uint reward = accountRewardDetails[msg.sender].accruedReward;
        if (reward > 0) {
            uint pastTime = block.timestamp.sub(accountRewardDetails[msg.sender].lastClaimTime);
            uint maturedReward = rewardReleasePeriod == 0 ? reward : reward.mul(pastTime).div(rewardReleasePeriod);
            if (maturedReward > reward) {
                maturedReward = reward;
            }

            accountRewardDetails[msg.sender].accruedReward = reward.sub(maturedReward);
            accountRewardDetails[msg.sender].lastClaimTime = block.timestamp;
            rewardsToken.safeTransfer(msg.sender, maturedReward);
            emit RewardPaid(msg.sender, maturedReward);
        }
    }

    function exit() external {
        withdraw(accountStakes[msg.sender]);
        getReward();
    }


    function notifyRewardAmount(uint reward) external onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp > startTime) {
            if (block.timestamp >= periodFinish) {
                require(reward < REWARD_OVERFLOW_CHECK, "reward rate will overflow");
                rewardRate = reward.div(rewardDuration);
            } else {
                uint remaining = periodFinish.sub(block.timestamp);
                uint leftover = remaining.mul(rewardRate);
                require(reward.add(leftover) < REWARD_OVERFLOW_CHECK, "reward rate will overflow");
                rewardRate = reward.add(leftover).div(rewardDuration);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(rewardDuration);
            emit RewardAdded(reward);
        } else {
            require(reward < REWARD_OVERFLOW_CHECK, "reward rate will overflow");
            rewardRate = reward.div(rewardDuration);
            lastUpdateTime = startTime;
            periodFinish = startTime.add(rewardDuration);
            emit RewardAdded(reward);
        }
    }

    function _setRewardDistribution(address _rewardDistribution) external onlyOwner {
        address oldRewardDistribution = rewardDistribution;
        rewardDistribution = _rewardDistribution;
        emit NewRewardDistribution(oldRewardDistribution, _rewardDistribution);
    }

    function _setRewardDuration(uint newRewardDuration) external onlyOwner updateReward(address(0)) {
        uint oldRewardDuration = rewardDuration;
        rewardDuration = newRewardDuration;

        if (block.timestamp > startTime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = 0;
            } else {
                uint remaining = periodFinish.sub(block.timestamp);
                uint leftover = remaining.mul(rewardRate);
                rewardRate = leftover.div(rewardDuration);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(rewardDuration);
        } else {
            rewardRate = rewardRate.mul(oldRewardDuration).div(rewardDuration);
            lastUpdateTime = startTime;
            periodFinish = startTime.add(rewardDuration);
        }

        emit NewRewardDuration(oldRewardDuration, newRewardDuration);
    }

    function _setRewardReleasePeriod(uint newRewardReleasePeriod) external onlyOwner updateReward(address(0)) {
        uint oldRewardReleasePeriod = rewardReleasePeriod;
        rewardReleasePeriod = newRewardReleasePeriod;
        emit NewRewardReleasePeriod(oldRewardReleasePeriod, newRewardReleasePeriod);
    }

    function _setCooldownTime(uint newCooldownTime) external onlyOwner {
        uint oldCooldownTime = claimCooldownTime;
        claimCooldownTime = newCooldownTime;
        emit NewCooldownTime(oldCooldownTime, newCooldownTime);
    }

}