// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/staking/IStaking.sol";

/** @title Staking
 * @notice It is a contract for Staking Legio
 */

contract Staking is Ownable, ReentrancyGuard, IStaking {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
        uint256 lastClaim;
    }

    struct PoolInfo {
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint256 depositedAmount;
        uint256 rewardsAmount;
        uint256 lockupDuration;
    }

    IERC20 public token;
    uint256 public tokenPerBlock = 1 ether; // 1 token

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public constant totalAllocPoint = 1000;

    uint256 public emergencyWithdrawFee = 100; // 10%

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPerBlockChanged(uint256 reward);
    event TokenAddressSet(address token);
    event StakingStarted(uint256 pid, uint256 startBlock);
    event PoolAdded(uint256 pid, uint256 allocPoint, uint256 lockupDuration);

    // mapping to check operator
    mapping(address => bool) public isOperator;

    /**
     * @notice modifier to check if pid is valid
     *
     * @param _pid: pool Id
     */
    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "should be EOA");
        _;
    }

    modifier isOperatorOrOwner() {
        require(isOperator[msg.sender] || owner() == msg.sender, "Not owner or operator");

        _;
    }

    /**
     * @notice constructor
     *
     * set owner to be operator
     */
    constructor(
    ) {
        isOperator[msg.sender] = true;
    }

    /**
     * @notice set operator
     */
    function setOperator(address user, bool bSet) external onlyOwner {
        require(user != address(0), "Invalid address");

        isOperator[user] = bSet;
    }

    /**
     * @notice function to add pool
     *
     * @param _allocPoint: Allocation Point of Pool
     * @param _lockupDuration: Timestamp of pool lock duration
     */
    function addPool(uint256 _allocPoint, uint256 _lockupDuration) internal {
        uint256 pid = poolInfo.length;
        poolInfo.push(
            PoolInfo({
                allocPoint: _allocPoint,
                lastRewardBlock: 0,
                accTokenPerShare: 0,
                depositedAmount: 0,
                rewardsAmount: 0,
                lockupDuration: _lockupDuration
            })
        );
        emit PoolAdded(pid, _allocPoint, _lockupDuration);
    }

    /**
     * @notice get Pending Rewards of a user in a certain pool
     *
     * @param pid: Pool Id
     * @param _user: User Address
     */
    function pendingRewards(uint256 pid, address _user) external view validatePoolByPid(pid) returns (uint256) {
        require(_user != address(0), "Invalid user address");
        require(poolInfo[pid].lastRewardBlock > 0, "Staking not yet started");
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 depositedAmount = pool.depositedAmount;
        if (block.number > pool.lastRewardBlock && depositedAmount != 0) {
            uint256 multiplier = block.number - (pool.lastRewardBlock);
            uint256 tokenReward = (multiplier * (tokenPerBlock) * (pool.allocPoint)) / (totalAllocPoint);
            accTokenPerShare = accTokenPerShare + ((tokenReward * (1e12)) / (depositedAmount));
        }
        return (user.amount * (accTokenPerShare)) / (1e12) - (user.rewardDebt) + (user.pendingRewards);
    }

    /**
     * @notice updatePool distribute pendingRewards
     *
     * @param pid: Pool Id
     */
    function updatePool(uint256 pid) internal validatePoolByPid(pid) {
        require(poolInfo[pid].lastRewardBlock > 0, "Staking not yet started");
        PoolInfo storage pool = poolInfo[pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 depositedAmount = pool.depositedAmount;
        if (pool.depositedAmount == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number - (pool.lastRewardBlock);
        uint256 tokenReward = (multiplier * (tokenPerBlock) * (pool.allocPoint)) / (totalAllocPoint);
        pool.rewardsAmount = pool.rewardsAmount + (tokenReward);
        pool.accTokenPerShare = pool.accTokenPerShare + ((tokenReward * (1e12)) / (depositedAmount));
        pool.lastRewardBlock = block.number;
    }

    /**
     * @notice deposit token to a certain pool
     *
     * @param pid: Pool Id
     * @param amount: Amount of token to deposit
     */
    function deposit(uint256 pid, uint256 amount) external validatePoolByPid(pid) onlyEOA {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        updatePool(pid);
        if (user.amount > 0) {
            uint256 pending = (user.amount * (pool.accTokenPerShare)) / (1e12) - (user.rewardDebt);
            if (pending > 0) {
                user.pendingRewards = user.pendingRewards + (pending);
            }
        }
        if (amount > 0) {
            token.safeTransferFrom(address(msg.sender), address(this), amount);
            user.amount = user.amount + (amount);
            pool.depositedAmount = pool.depositedAmount + (amount);
        }
        user.rewardDebt = (user.amount * (pool.accTokenPerShare)) / (1e12);
        user.lastClaim = block.timestamp;
        emit Deposit(msg.sender, pid, amount);
    }

    /**
     * @notice withdraw token from a certain pool
     *
     * @param pid: Pool Id
     * @param amount: Amount of token to deposit
     * @param _withdrawRewards: withdraw with rewards or not
     */
    function withdraw(
        uint256 pid,
        uint256 amount,
        bool _withdrawRewards
    ) external validatePoolByPid(pid) nonReentrant onlyEOA {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(block.timestamp > user.lastClaim + pool.lockupDuration, "You cannot withdraw yet!");
        require(user.amount >= amount, "Withdrawing more than you have!");
        updatePool(pid);
        uint256 pending = (user.amount * (pool.accTokenPerShare)) / (1e12) - (user.rewardDebt);
        if (pending > 0) {
            user.pendingRewards = user.pendingRewards + (pending);

            if (_withdrawRewards) {
                uint256 claimedAmount = safeTokenTransfer(msg.sender, user.pendingRewards, pid);
                emit Claim(msg.sender, pid, claimedAmount);
                user.pendingRewards = user.pendingRewards - claimedAmount;
            }
        }
        if (amount > 0) {
            token.safeTransfer(address(msg.sender), amount);
            user.amount = user.amount - (amount);
            pool.depositedAmount = pool.depositedAmount - (amount);
        }
        user.rewardDebt = (user.amount * (pool.accTokenPerShare)) / (1e12);
        user.lastClaim = block.timestamp;
        emit Withdraw(msg.sender, pid, amount);
    }

    /**
     * @notice emergency withdraw without rewards and fee
     *
     * @param pid: Pool Id
     * @param amount: Amount of token to deposit
     */
    function emergencyWithdraw(uint256 pid, uint256 amount) external validatePoolByPid(pid) nonReentrant onlyEOA {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        require(user.amount >= amount, "Withdrawing more than you have!");
        updatePool(pid);

        user.pendingRewards = 0;
        if (amount > 0) {
            uint256 amountToTransfer = (amount * (1000 - emergencyWithdrawFee)) / 1000; // extract fee
            token.safeTransfer(address(msg.sender), amountToTransfer);
            user.amount = user.amount - (amount);
            pool.depositedAmount = pool.depositedAmount - (amount);
        }
        user.rewardDebt = (user.amount * (pool.accTokenPerShare)) / (1e12);
        user.lastClaim = block.timestamp;
        emit Withdraw(msg.sender, pid, amount);
    }

    /**
     * @notice claim rewards from a certain pool
     *
     * @param pid: Pool Id
     */
    function claim(uint256 pid) external validatePoolByPid(pid) nonReentrant onlyEOA {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        updatePool(pid);
        uint256 pending = (user.amount * (pool.accTokenPerShare)) / (1e12) - (user.rewardDebt);
        if (pending > 0 || user.pendingRewards > 0) {
            user.pendingRewards = user.pendingRewards + (pending);
            uint256 claimedAmount = safeTokenTransfer(msg.sender, user.pendingRewards, pid);
            emit Claim(msg.sender, pid, claimedAmount);
            user.pendingRewards = user.pendingRewards - (claimedAmount);
            user.lastClaim = block.timestamp;
            pool.rewardsAmount = pool.rewardsAmount - (claimedAmount);
        }
        user.rewardDebt = (user.amount * (pool.accTokenPerShare)) / (1e12);
    }

    function safeTokenTransfer(
        address to,
        uint256 amount,
        uint256 pid
    ) internal returns (uint256) {
        PoolInfo memory pool = poolInfo[pid];
        if (amount > pool.rewardsAmount) {
            token.safeTransfer(to, pool.rewardsAmount);
            return pool.rewardsAmount;
        } else {
            token.safeTransfer(to, amount);
            return amount;
        }
    }

    function getDepositedAmount(address user) external view override returns (uint256) {
        uint256 amount = 0;
        for (uint256 index = 0; index < poolInfo.length; index++) {
            amount = amount + userInfo[index][user].amount;
        }
        return amount;
    }

    function withdrawAnyToken(IERC20 _token, uint256 amount) external isOperatorOrOwner {
        _token.safeTransfer(msg.sender, amount);
    }

    function setToken(IERC20 _token) external isOperatorOrOwner {
        require(address(token) == address(0), "Token already set!");
        require(address(_token) != address(0), "Invalid Token Address");

        token = _token;

        emit TokenAddressSet(address(token));

        addPool(1000, 365 days);
    }

    function startStaking(uint256 startBlock) external isOperatorOrOwner {
        require(poolInfo[0].lastRewardBlock == 0, "Staking already started");
        poolInfo[0].lastRewardBlock = startBlock;
        emit StakingStarted(0, startBlock);
    }

    function setTokenPerBlock(uint256 _tokenPerBlock) external isOperatorOrOwner {
        require(_tokenPerBlock > 0, "Token per block should be greater than 0!");
        tokenPerBlock = _tokenPerBlock;

        emit RewardPerBlockChanged(_tokenPerBlock);
    }

    function setEmergencyWithdrawFee(uint256 _emergencyWithdrawFee) external isOperatorOrOwner {
        require(_emergencyWithdrawFee < 1000, "Fee can't be 100%");
        require(_emergencyWithdrawFee > 0, "Fee can't be 0");

        emergencyWithdrawFee = _emergencyWithdrawFee;
    }
}