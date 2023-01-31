pragma solidity ^0.5.0;

import "../openzeppelin/Math.sol";
import "../perpStaking/IPerpRewardDistribution.sol";
import "./LockedLPTokenWrapper.sol";
import "./LockedPoolEscrow.sol";
import "../staking/StakingWhitelist.sol";

contract LockedTokenRewards is
    LockedLPTokenWrapper,
    IPerpRewardDistribution,
    StakingWhitelistable
{
    IERC20 public snx;
    uint256 public constant DURATION = 14 days;

    address public escrow;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    bool public onlyWhitelisted = true;
    bool public allowRewards = false;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier rewardStatus() {
        require(allowRewards == true, "Rewards are not available to claim yet");
        _;
    }

    modifier checkWhitelistStatus(address account) {
        require(
            isWhitelisted(account) == true || onlyWhitelisted == false,
            "Currently only Whitelisted Addresses can stake"
        );
        _;
    }

    constructor(address _token, address _lp) public LockedLPTokenWrapper(_lp) {
        snx = IERC20(_token);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // returns the earned amount as it will be paid out by the escrow (accounting for rebases)
    function earnedTokens(address account) public view returns (uint256) {
        return
            LockedPoolEscrow(escrow).getTokenNumber(
                balanceOf(account)
                    .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                    .div(1e18)
                    .add(rewards[account])
            );
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    // Duration here is in days
    function stakeOnBehalf(
        address user,
        uint256 amount,
        uint256 duration
    ) public updateReward(user) checkWhitelistStatus(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stakeOnBehalf(user, amount, duration);
        emit Staked(user, amount);
        notifier.notifyStaked(user, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
        notifier.notifyWithdrawn(msg.sender, amount);
    }

    function getReward() public updateReward(msg.sender) rewardStatus{
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            // the pool is distributing placeholder tokens with fixed supply
            snx.safeApprove(escrow, 0);
            snx.safeApprove(escrow, reward);
            LockedPoolEscrow(escrow).release(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(
        uint256 reward
    ) external onlyRewardDistribution updateReward(address(0)) {
        // overflow fix https://sips.synthetix.io/sips/sip-77
        require(reward < uint256(-1) / 1e18, "amount too high");

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    function setEscrow(address newEscrow) external onlyOwner {
        require(escrow == address(0), "escrow already set");
        escrow = newEscrow;
    }

    function setStatus(bool status) external onlyOwner {
        onlyWhitelisted = status;
    }

    function setReward(bool status) external onlyOwner {
        allowRewards = status;
    }

    function whitelistAddress(address target) external onlyOwner {
        _whitelistAccount(target);
    }

    function delistAddress(address target) external onlyOwner {
        _delistAccount(target);
    }

    function recoverTokens(
        address _token,
        address benefactor
    ) public onlyOwner {
        //require(_token != address(uni), "Cannot transfer LP tokens"); For initial release we remove the requirement
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(benefactor, tokenBalance);
    }
}