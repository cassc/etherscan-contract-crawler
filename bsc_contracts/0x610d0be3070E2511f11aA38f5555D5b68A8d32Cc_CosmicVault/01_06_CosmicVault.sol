// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract RewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "!distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }

    constructor() {
        rewardDistribution = msg.sender;
    }
}

interface ICosmicMoon {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract VaultWrapper {
    using SafeMath for uint256;

    ICosmicMoon public stakedToken;

    uint256 public feeDenominator = 10000;
    uint256 public withdrawFee = 0;
    uint256 public depositFee = 0;

    address public feeReceiver = 0xb4C2A0530430eFA7A6CEc36cAd59F73243cD4734;

    uint256 private _totalReflections;
    mapping(address => uint256) private _reflections;

    constructor(address _stakedToken) {
        stakedToken = ICosmicMoon(_stakedToken);
    }

    function totalSupply() public view returns (uint256) {
        return _totalReflections;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _reflections[account];
    }

    function stake(uint256 amount) public virtual {
        if (depositFee > 0) {
            uint256 feeAmount = amount.mul(depositFee).div(feeDenominator);
            stakedToken.transferFrom(msg.sender, feeReceiver, feeAmount);
            amount = amount.sub(feeAmount);
        }
        _totalReflections = _totalReflections.add(amount);
        _reflections[msg.sender] = _reflections[msg.sender].add(amount);
        stakedToken.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        if (withdrawFee > 0) {
            uint256 feeAmount = amount.mul(withdrawFee).div(feeDenominator);
            stakedToken.transfer(feeReceiver, feeAmount);
            amount = amount.sub(feeAmount);
        }
        _totalReflections = _totalReflections.sub(amount);
        _reflections[msg.sender] = _reflections[msg.sender].sub(amount);
        // don't deduct fee before transfer
        stakedToken.transfer(msg.sender, amount);
    }
}

contract CosmicVault is VaultWrapper, RewardDistributionRecipient {
    using SafeMath for uint256;

    IERC20 public rewardToken;
    uint256 public duration;
    uint256 public capPerAddress;

    uint256 public withdrawalInterval;

    uint256 public constant MAXIMUM_WITHDRAWAL_INTERVAL = 10000 days;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => UserInfo) public userInfo;

    bool public isStopped = false;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 nextWithdrawalUntil; // When can the user withdraw again.
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event EmergencyRewardWithdraw(address indexed user, uint256 amount);
    event EmergencyTokenWithdraw(
        address indexed user,
        address token,
        uint256 amount
    );
    event UpdateCapPerAddress(uint256 newAmount);
    event NewWithdrawalInterval(uint256 interval);

    constructor(
        address _stakedToken,
        address _rewardToken,
        uint256 _duration,
        uint256 _capPerAddress,
        uint256 _withdrawalInterval
    ) VaultWrapper(_stakedToken) RewardDistributionRecipient() {
        require(_duration > 0, "Cannot set duration 0");
        require(
            _withdrawalInterval <= MAXIMUM_WITHDRAWAL_INTERVAL,
            "Invalid withdrawal interval"
        );
        rewardToken = IERC20(_rewardToken);
        duration = _duration;
        capPerAddress = _capPerAddress;
        withdrawalInterval = _withdrawalInterval;
    }

    function canWithdraw(address account) external view returns (bool) {
        UserInfo storage user = userInfo[account];
        return (isStopped || block.timestamp >= user.nextWithdrawalUntil);
    }

    modifier updateReward(address account) {
        UserInfo storage user = userInfo[account];

        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            user.amount = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (
            totalSupply() == 0 || lastTimeRewardApplicable() == lastUpdateTime
        ) {
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
        UserInfo storage user = userInfo[account];

        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(user.amount);
    }

    function stake(uint256 amount) public override updateReward(msg.sender) {
        UserInfo storage user = userInfo[msg.sender];

        require(amount > 0, "Cannot stake 0");
        require(periodFinish > 0, "Pool not started yet");

        if (capPerAddress > 0) {
            require(
                balanceOf(msg.sender).add(amount) <= capPerAddress,
                "Cap per address reached"
            );
        }

        super.stake(amount);

        user.nextWithdrawalUntil = block.timestamp.add(withdrawalInterval);

        if (user.nextWithdrawalUntil >= periodFinish) {
            user.nextWithdrawalUntil = periodFinish;
        }

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        UserInfo storage user = userInfo[msg.sender];
        require(amount > 0, "Cannot withdraw 0");
        require(
            isStopped || block.timestamp >= user.nextWithdrawalUntil,
            "Withdrawal locked"
        );

        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        UserInfo storage user = userInfo[msg.sender];
        require(
            isStopped || block.timestamp >= user.nextWithdrawalUntil,
            "Withdrawal locked"
        );

        withdraw(balanceOf(msg.sender));
        getReward();

        user.nextWithdrawalUntil = 0;
    }

    function getReward() public updateReward(msg.sender) {
        UserInfo storage user = userInfo[msg.sender];

        uint256 reward = earned(msg.sender);

        if (reward > 0) {
            user.amount = 0;
            safeRewardsTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function safeRewardsTransfer(address _to, uint256 _amount) internal {
        if (rewardToken.balanceOf(address(this)) > 0) {
            uint256 rewardBal = rewardToken.balanceOf(address(this));
            if (_amount >= rewardBal) {
                rewardToken.transfer(_to, rewardBal);
            } else if (_amount > 0) {
                rewardToken.transfer(_to, _amount);
            }
        }
    }

    function notifyRewardAmount(uint256 newRewards)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = newRewards.div(duration);
        } else {
            uint256 remainingTime = periodFinish.sub(block.timestamp);
            uint256 leftoverRewards = remainingTime.mul(rewardRate);
            rewardRate = newRewards.add(leftoverRewards).div(duration);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);

        emit RewardAdded(newRewards);
    }

    function emergencyRewardWithdraw(uint256 amount) external onlyOwner {
        require(
            amount <= rewardToken.balanceOf(address(this)),
            "not enough token"
        );
        safeRewardsTransfer(msg.sender, amount);
        emit EmergencyRewardWithdraw(msg.sender, amount);
    }

    function emergencyTokenWithdraw(address _token, uint256 _amount)
        external
        onlyOwner
    {
        IERC20 token = IERC20(_token);

        uint256 amount = _amount;

        if (amount > token.balanceOf(address(this))) {
            amount = token.balanceOf(address(this));
        }

        token.transfer(msg.sender, amount);
        emit EmergencyTokenWithdraw(msg.sender, _token, amount);
    }

    function stopPool() external onlyOwner {
        isStopped = true;
        rewardRate = 0;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
    }

    function setCapPerAddress(uint256 _newCap) external onlyOwner {
        capPerAddress = _newCap;

        emit UpdateCapPerAddress(_newCap);
    }

    function updateWithdrawalInterval(uint256 _interval) external onlyOwner {
        require(
            _interval <= MAXIMUM_WITHDRAWAL_INTERVAL,
            "Invalid withdrawal interval"
        );
        withdrawalInterval = _interval;
        emit NewWithdrawalInterval(_interval);
    }

    function setFeeReceiver(address feeReceiver_) public onlyOwner {
        feeReceiver = feeReceiver_;
    }

    function setDepositFee(uint256 depositFee_) public onlyOwner {
        depositFee = depositFee_;
    }

    function setWithdrawFee(uint256 withdrawFee_) public onlyOwner {
        withdrawFee = withdrawFee_;
    }
}