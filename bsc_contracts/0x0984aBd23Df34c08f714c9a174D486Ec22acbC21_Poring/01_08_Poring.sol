// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/Math.sol";

import "./interfaces/IProntera.sol";

abstract contract JellopyWrapper {
    IProntera public immutable prontera;
    address public immutable izlude;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(IProntera _prontera, address _izlude) {
        prontera = _prontera;
        izlude = _izlude;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        prontera.storeKeepJellopy(msg.sender, izlude, amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        prontera.storeReturnJellopy(msg.sender, izlude, amount);
    }
}

contract Poring is JellopyWrapper, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    uint256 public duration;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerJellopyStored;
    mapping(address => uint256) public userRewardPerJellopyPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        IProntera prontera,
        address izlude,
        address _rewardToken,
        uint256 _duration
    ) JellopyWrapper(prontera, izlude) {
        rewardToken = IERC20(_rewardToken);
        duration = _duration;
    }

    modifier updateReward(address account) {
        rewardPerJellopyStored = rewardPerJellopy();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerJellopyPaid[account] = rewardPerJellopyStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerJellopy() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerJellopyStored;
        }
        uint256 r = (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18;
        r /= totalSupply();
        return rewardPerJellopyStored + r;
    }

    function earned(address account) public view returns (uint256) {
        uint256 r = rewardPerJellopy() - userRewardPerJellopyPaid[account];
        return ((balanceOf(account) * r) / 1e18) + rewards[account];
    }

    // stake visibility is public as overriding JellopyWrapper's stake() function
    function stake(uint256 amount) public override(JellopyWrapper) updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override(JellopyWrapper) updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount() external onlyOwner updateReward(address(0)) {
        require(periodFinish == 0, "!notified");

        uint256 reward = IERC20(rewardToken).balanceOf(address(this));

        require(reward != 0, "no rewards");

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / duration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / duration;
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;
        emit RewardAdded(reward);
    }

    function inCaseTokensGetStuck(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        inCaseTokensGetStuck(token, msg.sender, amount);
    }

    function inCaseTokensGetStuck(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}