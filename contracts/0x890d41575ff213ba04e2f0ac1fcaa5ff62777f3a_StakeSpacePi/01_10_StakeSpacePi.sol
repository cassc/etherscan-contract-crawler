// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Relationship} from "./utils/Relationship.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakeSpacePi is ReentrancyGuard, Relationship {
    using SafeERC20 for IERC20;
    struct Pool {
        uint256 apr; // pool apr
        uint256 lockSeconds; // pool lock seconds
        uint256 amount; // pool stake amount
    }

    struct UserInfo {
        uint256 amount; // user deposit amount
        uint256 accReward; // user accumulate reward
        uint256 rewardDebt; // user reward debt
        uint256 enterTime; // user enter timestamp
        uint256 billedSeconds; // user billed seconds
    }

    Pool[] public pools; // stake pools
    IERC20 public token; // using token
    uint256 public accDeposit; // accumulate all deposit
    uint256 public accReward; // accumulate all reward

    uint256 public constant inviteRewardRate = 10; // invite reward rate

    mapping(address => mapping(uint256 => UserInfo)) public userInfo; // user info

    mapping(address => uint256) public inviteReward; // invite reward amount

    event Deposit(address indexed user, uint256 indexed pid, uint256 indexed amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 indexed amount);
    event InviterReward(address indexed user, uint256 indexed pid, uint256 indexed amount);
    event Reward(address indexed user, uint256 indexed pid, uint256 indexed amount);
    event AddPool(uint256 indexed apr, uint256 indexed locked, uint256 indexed pid);
    event SetPool(uint256 indexed apr, uint256 indexed locked, uint256 indexed pid);

    constructor(IERC20 _token,uint256 end)Relationship(end){
        token = _token;
    }
    modifier onlyUnLock(uint256 pid, address _sender){
        Pool memory pool = pools[pid];
        UserInfo memory user = userInfo[_sender][pid];
        require(block.timestamp >= pool.lockSeconds + user.enterTime, "onlyUnLock: locked");
        _;
    }
    modifier onlyNotDeposit() {
        require(accDeposit == 0, "onlyNotDeposit: only not deposit");
        _;
    }

    modifier onlyInvited(address _sender){
        require(getParent(_sender) != address(0), "onlyInvited:only invited");
        _;
    }
    // @dev add a new stake pool
    function addPool(uint256 apr,uint256 locked) external onlyOwner{
        require(apr > 5, "setPool: apr must > 5");
        require(apr < 500, "setPool: apr must < 500");
        require(locked > 0, "setPool: locked must > 0");
        pools.push(Pool(apr, locked, 0));
        emit AddPool(apr, locked, pools.length - 1);
    }
    // @dev total pools length
    function poolLength() external view returns (uint256) {
        return pools.length;
    }
    // @dev modify pool apr and lock time
    function setPool(uint256 pid, uint256 apr, uint256 locked) external onlyOwner onlyNotDeposit{
        require(apr > 5, "setPool: apr must > 5");
        require(apr < 500, "setPool: apr must < 500");
        require(locked > 0, "setPool: locked must > 0");
        pools[pid].apr = apr;
        pools[pid].lockSeconds = locked;
        emit SetPool(apr, locked, pid);
    }
    // @dev get user pending reward
    function pending(uint256 pid, address play) public view returns (uint256){
        uint256 time = block.timestamp;
        Pool memory pool = pools[pid];
        UserInfo memory user = userInfo[play][pid];
        if (user.amount == 0) return 0;
        // reward formula = (amount * apr * delta elapsed time) + billing unclaimed
        uint256 perSecond = user.amount * pool.apr * 1e18 / 365 days / 100;
        if (time >= pool.lockSeconds + user.enterTime) {
            if (user.billedSeconds >= pool.lockSeconds) return 0;
            return (perSecond * (pool.lockSeconds - user.billedSeconds) / 1e18)+user.rewardDebt;
        }
        return (perSecond*(time- user.enterTime-user.billedSeconds) / 1e18)+user.rewardDebt;
    }

    // @dev deposit token can repeat, will settle the previous deposit
    // @dev only invited can deposit
    function deposit(uint256 pid, uint256 amount) external nonReentrant onlyInvited(msg.sender) inDuration {
        require(amount > 0, "deposit: amount must > 0");
        Pool storage pool = pools[pid];
        UserInfo storage user = userInfo[msg.sender][pid];
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 reward = pending(pid, msg.sender);
        uint256 currentBlock = block.timestamp;
        // if user first deposit, set enter time
        if (user.enterTime == 0) {
            user.enterTime = block.timestamp;
        }
        // if lock-up time period is over, reset enter time
        if (currentBlock > user.enterTime+ pool.lockSeconds) {
            if (reward > 0) revert("deposit: reward claim first");
            user.enterTime = block.timestamp;
        }
        // if user has deposit, settle the previous deposit
        if (user.amount > 0) {
            if (reward > 0) {
                user.rewardDebt = reward;
                user.billedSeconds = block.timestamp - user.enterTime;
            }
        }
        // record user deposit amount
        pool.amount = pool.amount + amount;
        user.amount = user.amount + amount;
        accDeposit = accDeposit + amount;
        emit Deposit(msg.sender, pid, amount);
    }
    // @dev withdraw deposit token whether unlock
    function withdraw(uint256 pid) external onlyUnLock(pid, msg.sender) {
        UserInfo storage user = userInfo[msg.sender][pid];
        Pool storage pool = pools[pid];
        uint256 amount = user.amount;
        uint256 reward = pending(pid, msg.sender);
        require(user.amount >= 0, "withdraw: Principal is zero");
        // If there is a reward, first receive the reward before receiving the deposit
        if (reward > 0) claim(pid);
        // reset record
        user.amount = 0;
        user.enterTime = 0;
        user.billedSeconds = 0;

        accDeposit = accDeposit - amount;
        pool.amount = pool.amount - amount;
        // withdraw deposit amount
        token.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, pid, amount);
    }

    // @dev claim interest, not locking withdraw
    // @dev inviter will get setting percent of the interest
    function claim(uint256 pid) public nonReentrant{
        UserInfo storage user = userInfo[msg.sender][pid];
        Pool memory pool = pools[pid];
        uint256 reward = pending(pid, msg.sender);
        require(reward > 0, "claim: interest is zero");
        // if not enough reward, will claim all remaining reward
        if (token.balanceOf(address(this)) - accDeposit >= reward) {
            address inviter = getParent(msg.sender);
            // calc inviter reward
            uint256 userInviteReward = reward * inviteRewardRate / 100;
            // calc user reward
            uint256 userReward = reward - userInviteReward;
            // transfer reward
            token.safeTransfer(inviter, userInviteReward);
            token.safeTransfer(msg.sender, userReward);

            user.accReward = user.accReward + userReward;

            if ((block.timestamp - user.enterTime) >= pool.lockSeconds) {
                // lock-up time period ends, set to lock seconds
                user.billedSeconds = pool.lockSeconds;
            } else {
                // If not finished, calculate the elapsed time from the start
                user.billedSeconds = block.timestamp - user.enterTime;
            }
            // record info
            user.rewardDebt = 0;
            accReward = accReward + reward;
            inviteReward[inviter] = inviteReward[inviter] + userInviteReward;
            emit InviterReward(inviter, pid, userInviteReward);
            emit Reward(msg.sender, pid, userReward);
        }
    }

}