// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/Math.sol";

contract CeVeloRewardPool is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public duration;

    uint256 private _totalSupply;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardBalance;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;
    mapping(address => bool) public whitelist;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event AddedWhiteList(address strategy);
    event RemovedWhitelist(address strategy);

    constructor(address _token, uint256 _duration) {
        token = IERC20(_token);
        duration = _duration;
    }

    modifier onlyWhitelist(address account) {
        require(whitelist[account] == true, "RewardPool: WHITE_LIST_ONLY");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (
                (lastTimeRewardApplicable() - lastUpdateTime)
                * rewardRate
                * 1e18
                / totalSupply()
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                * (rewardPerToken() - userRewardPerTokenPaid[account])
                / 1e18
                + rewards[account];
    }

    function stake(uint256 amount) public updateReward(msg.sender) onlyWhitelist(msg.sender) {
        require(amount > 0, "RewardPool: ZERO_AMOUNT");
        _totalSupply = _totalSupply + amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) onlyWhitelist(msg.sender) {
        require(amount > 0, "RewardPool: ZERO_AMOUNT");
        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            if (reward > rewardBalance) {
                reward = rewardBalance;
            }
            rewardBalance = rewardBalance - reward;
            rewards[msg.sender] = 0;
            token.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Add depositing strategy to whitelist
    function addWhitelist(address _strategy) external onlyOwner {
        whitelist[_strategy] = true;
        emit AddedWhiteList(_strategy);
    }

    // remove depositing strategy from whitelist
    function removeWhitelist(address _strategy) external onlyOwner {
        whitelist[_strategy] = false;
        emit RemovedWhitelist(_strategy);
    }

    function notifyRewardAmount()
        external
        updateReward(address(0))
    {
        uint256 balance = token.balanceOf(address(this));
        uint256 newRewards = balance - rewardBalance;
        if (newRewards > 0) {
            if (block.timestamp >= periodFinish) {
                rewardRate = newRewards / duration;
            } else {
                uint256 remaining = periodFinish - block.timestamp;
                uint256 leftover = remaining * rewardRate;
                rewardRate = (newRewards + leftover) / duration;
            }
            rewardBalance = rewardBalance + newRewards;
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp + duration;
            emit RewardAdded(newRewards);
        }
    }

    function inCaseTokensGetStuck(address _token) external onlyOwner {
        if (totalSupply() != 0) {
            require(_token != address(token), "RewardPool: STUCK_TOKEN_ONLY");
        }
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }
}