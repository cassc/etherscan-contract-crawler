// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./lib/reentrancy-guard.sol";
import "./lib/pausable.sol";
import "./lib/owned.sol";
import "./base/ERC20.sol";

contract EpikStaking is ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    struct WithdrawingRequest { 
        uint104 withdrawableAmount;
        uint104 requestedAmount;
        uint48 requestedTime;
    }

    mapping(address => WithdrawingRequest) public userWithdrawingRequest;

    uint128 public rewardRate = 0;
    uint128 private _totalSupply;

    uint96 public rewardPerTokenStored;
    uint32 public cooldown = 12 days;
    uint32 public rewardsDuration = 30 days;
    uint48 public periodFinish = 0;
    uint48 public lastUpdateTime;

    uint96 public withdrawFee = 0;
    address payable public withdrawVault;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    address[] private _managers;

    IERC20 public immutable stakingToken;

    uint32 constant public MAX_COOLDOWN_DURATION = 60 days;
    string constant public name = "PRIME";
    string constant public symbol = "PRIME";
    uint8 constant public decimals = 18;

    uint256 constant public MAX_WITHDRAW_FEE = 5 * 1e17;    // 0.5 eth

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, address _stakingToken) Owned(_owner) {
        stakingToken = IERC20(_stakingToken);
    }

    modifier onlyManager {
        bool isManager = false;

        if (owner == msg.sender) {
            isManager = true;
        }

        if (isManager == false) {
            for (uint256 i = 0; i < _managers.length; i++) {
                if (_managers[i] == msg.sender) {
                    isManager = true;
                    break;
                }
            }
        }

        require(
            isManager == true,
            "Only the contract manager may perform this action"
        );

        _;
    }

    /* ========== VIEWS ========== */
    function getManagers() external view returns (address[] memory) {
        return _managers;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / _totalSupply;
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount)
        external
        nonReentrant
        notPaused
    {
        require(amount > 0, "Stake: Cannot stake 0");

        uint256 _userWithdrawRequestedTime = userWithdrawingRequest[msg.sender].requestedTime;
        if (_userWithdrawRequestedTime > 0) {
            require((_userWithdrawRequestedTime + cooldown) <= block.timestamp, "Stake: withdraw request still in pending");
        }

        _updateReward(msg.sender);
        _totalSupply = _totalSupply + uint128(amount);

        _balances[msg.sender] = _balances[msg.sender] + amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    function withdrawRequest(uint256 amount) external {
        require(amount > 0, "Withdraw Request: Cannot withdraw request 0");

        WithdrawingRequest memory prevRequest = userWithdrawingRequest[msg.sender];
        uint256 currentTime = block.timestamp;

        // Check cooldown status
        if (prevRequest.requestedTime > 0) {
            require((prevRequest.requestedTime + cooldown) <= currentTime, "Withdraw Request: withdraw request still in pending");
        }

        require(_balances[msg.sender] >= (amount + prevRequest.withdrawableAmount + prevRequest.requestedAmount), "Withdraw Request: Can not request the amount. Insufficient staking amount");

        userWithdrawingRequest[msg.sender].withdrawableAmount = prevRequest.withdrawableAmount + prevRequest.requestedAmount;
        userWithdrawingRequest[msg.sender].requestedAmount = uint104(amount);
        userWithdrawingRequest[msg.sender].requestedTime = uint48(currentTime);

        emit WithdrawRequested(cooldown, msg.sender, currentTime, amount);
    }

    function withdraw(uint256 amount)
        external
        payable
        nonReentrant
    {
        require(amount > 0, "Withdraw: Cannot withdraw 0");

        if (withdrawFee > 0) {
            require(withdrawFee == msg.value, "Withdraw Request: fee is not correct");

            if (withdrawVault != address(0)) {
                (bool sent,) = withdrawVault.call{value: msg.value}("");
                require(sent, "Withdraw Request: Failed to send Fee");
            }
        }

        WithdrawingRequest memory prevRequest = userWithdrawingRequest[msg.sender];

        // Check cooldown status and update withdrawRequesting status
        if ((prevRequest.requestedTime + cooldown) <= block.timestamp) {
            prevRequest.withdrawableAmount = prevRequest.withdrawableAmount + prevRequest.requestedAmount;
            prevRequest.requestedTime = 0;
            prevRequest.requestedAmount = 0;
        }

        uint256 senderBalance = _balances[msg.sender];

        require(senderBalance >= amount, "Withdraw: Can not withdraw the amount. Insufficient balance");
        require(prevRequest.withdrawableAmount >= amount, "Withdraw: Can not withdraw the amount. Insufficient withdrawable balance");

        userWithdrawingRequest[msg.sender].withdrawableAmount = uint104(prevRequest.withdrawableAmount - amount);
        userWithdrawingRequest[msg.sender].requestedTime = prevRequest.requestedTime;
        userWithdrawingRequest[msg.sender].requestedAmount = prevRequest.requestedAmount;

        _updateReward(msg.sender);
        _totalSupply = uint128(_totalSupply - amount);

        _balances[msg.sender] = senderBalance - amount;
        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function withdrawCancel() external
    {
        WithdrawingRequest memory request = userWithdrawingRequest[msg.sender];

        require(request.requestedTime > 0, "Withdraw Cancel: no request");
        require((request.requestedTime + cooldown) > block.timestamp, "Withdraw Cancel: no pending request");

        userWithdrawingRequest[msg.sender].requestedTime = 0;
        userWithdrawingRequest[msg.sender].requestedAmount = 0;

        emit WithdrawCancelled(msg.sender, request.requestedTime, request.requestedAmount);
    }

    function claimReward() public nonReentrant {
        _updateReward(msg.sender);

        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            
            // Sending ETH
            (bool sent,) = msg.sender.call{value: reward}("");
            require(sent, "Claim: Failed to send Ether");

            emit RewardPaid(msg.sender, reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward)
        external
        onlyManager
    {
        _updateReward(address(0));

        uint256 _rewardsDuration = rewardsDuration;

        if (block.timestamp >= periodFinish) {
            rewardRate = uint128(reward / _rewardsDuration);
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = uint128((reward + leftover) / _rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = address(this).balance;
        require(
            rewardRate <= balance / _rewardsDuration,
            "Notify Reward: Provided reward too high"
        );

        lastUpdateTime = uint48(block.timestamp);

        periodFinish = uint48(block.timestamp + _rewardsDuration);

        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyManager {
        require(
            block.timestamp > periodFinish,
            "Set Rewards Duration: Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = uint32(_rewardsDuration);
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function _updateReward(address account) internal {
        rewardPerTokenStored = uint96(rewardPerToken());
        lastUpdateTime = uint48(lastTimeRewardApplicable());
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    function setCooldown(uint256 _cooldown) external onlyManager {
        require(_cooldown <= MAX_COOLDOWN_DURATION, "Set Cooldown: Too high cooldown");
        cooldown = uint32(_cooldown);
    }

    /* ========== SUPER ADMIN FUNCTIONS ========== */

    function setWithdrawFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAX_WITHDRAW_FEE, "Too high fee");
        withdrawFee = uint96(_fee);
    }

    function setWithdrawVault(address payable _vault) external onlyOwner {
        withdrawVault = _vault;
    }

    function addManager(address account) external onlyOwner {
        bool isExisting = false;
        for (uint256 i = 0; i < _managers.length; i++) {
            if (_managers[i] == account) {
                isExisting = true;
                break;
            }
        }
        if (isExisting == false) {
            _managers.push(account);
        }
    }

    function removeManager(uint256 index) external onlyOwner {
        _managers[index] = _managers[_managers.length - 1];
        _managers.pop();
    }

    fallback() external payable {}
    receive() external payable {}

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);

    event WithdrawRequested(uint256 cooldown, address indexed withdrawer, uint256 withdrawTime, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event WithdrawCancelled(address indexed user, uint256 cooldown, uint256 amount);
}