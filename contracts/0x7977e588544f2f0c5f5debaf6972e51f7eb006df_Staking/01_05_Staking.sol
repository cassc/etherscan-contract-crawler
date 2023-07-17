// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./interfaces/IERC20.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/EnumerableSet.sol";

contract Staking {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    mapping (address => EnumerableSet.UintSet) orderList;
    
    uint256 idx;
    bool private entered;
    address public owner;

    IERC20 public L;

    struct Order {
        address owner;
        uint256 amount;
        uint256 shares;
        uint256 debt;
        uint256 multiplier;
        uint256 stakeTime;
        uint256 unstakeTime;
    }
    mapping (uint256 => Order) public orders;
    mapping (uint256 => uint256) public multipliers;

    uint256 public totalAmountStaked;
    uint256 public totalShares;
    uint256 public rewardPerSecond;
    uint256 public accRewardPerShare;
    uint256 public totalReward;
    uint256 public lastRewardTime;
    uint256 public deadline;

    // ============ Events ============

    event MultiplierEnabled(uint256 indexed day, uint256 indexed multiplier);
    event OwnershipTransferred(address indexed user, address indexed newOwner);
    event RewardPerSecondChanged(uint256 indexed rewardPerSecond, uint256 startTime, uint256 endTime);
    event Staked(address indexed account, uint256 indexed amount);
    event Unstaked(address indexed account, uint256 indexed amount, uint256 reward);

    constructor(address token) {
        L = IERC20(token);

        multipliers[0] = 1 ether;
        emit MultiplierEnabled(0, 1 ether);

        multipliers[30] = 1.2 ether;
        emit MultiplierEnabled(30, 1.2 ether);

        multipliers[60] = 1.5 ether;
        emit MultiplierEnabled(60, 1.5 ether);

        multipliers[90] = 2 ether;
        emit MultiplierEnabled(90, 2 ether);

        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // ============ Modifiers ============

    modifier nonReentrant() {
        require(!entered, "reentrant");
        entered = true;
        _;
        entered = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized");

        _;
    }

    // ============ Routine Functions ============

    function stake(uint256 amount, uint256 day) external nonReentrant {
        require(amount > 0, "amount must be greater than 0");
        require(L.balanceOf(msg.sender) >= amount, "insufficient balance");
        require(L.allowance(msg.sender, address(this)) >= amount, "insufficient allowance");

        update();

        uint256 multiplier = multipliers[day];
        require(multiplier != 0, "multiplier does not exist");

        L.safeTransferFrom(msg.sender, address(this), amount);
        idx++;
        Order storage order = orders[idx];
        order.owner = msg.sender;
        order.amount += amount;
        order.shares = amount * multiplier / 10**18;
        order.debt = order.shares * accRewardPerShare / 10**18;
        order.multiplier = multiplier;
        order.stakeTime = block.timestamp;
        order.unstakeTime = block.timestamp + day * 86400;

        addOrder(msg.sender, idx);

        totalAmountStaked += amount;
        totalShares += order.shares;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 id) external nonReentrant {
        Order storage order = orders[id];

        uint256 amount = order.amount;
        require(amount > 0, "not exist");

        require(order.owner == msg.sender, "only owner");
        require(order.unstakeTime < block.timestamp, "not due");

        update();

        uint256 reward = order.shares * accRewardPerShare / 10**18 - order.debt;

        totalAmountStaked -= amount;
        totalShares -= order.shares;

        delOrder(msg.sender, id);
        delete orders[id];

        L.safeTransfer(msg.sender, amount + reward);

        emit Unstaked(msg.sender, amount, reward);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    function changeRewardPerSecond(uint256 newRewardPerSecond, uint256 newDeadline) external onlyOwner {
        update();

        require(newDeadline > lastRewardTime, "forbid");

        uint256 balance = (newDeadline - lastRewardTime) * newRewardPerSecond;
        if (totalReward < balance) {
            balance -= totalReward;
            totalReward += balance;
            L.safeTransferFrom(msg.sender, address(this), balance);
        }
        
        rewardPerSecond = newRewardPerSecond;
        deadline = newDeadline;

        emit RewardPerSecondChanged(rewardPerSecond, lastRewardTime, deadline);
    }

    function enabledMultiplier(uint256 day, uint256 multiplier) external onlyOwner {
        multipliers[day] = multiplier;
        emit MultiplierEnabled(day, multiplier);
    }

    // ============ View Functions ============

    function earned(uint256 id) external view returns (uint256) {
        Order memory order = orders[id];

        if (order.amount == 0) {
            return 0;
        }

        uint256 ts;
        if (block.timestamp >= deadline) {
            if (deadline > lastRewardTime) {
                ts = deadline - lastRewardTime;
            }
        } else {
            ts = block.timestamp - lastRewardTime;
        }

        uint256 reward = rewardPerSecond * ts;
        if (totalReward < reward) {
            reward = totalReward;
        }
        uint256 _accRewardPerShare = accRewardPerShare + reward * 10**18 / totalShares;
        return order.shares * _accRewardPerShare / 10**18 - order.debt;
    }

    function getOrderLength(address account) public view returns (uint256) {
        return EnumerableSet.length(orderList[account]);
    }

    function getOrderList(address account) public view returns (uint256[] memory) {
        return EnumerableSet.values(orderList[account]);
    }

    function isOrderExist(address account, uint256 id) public view returns (bool) {
        return EnumerableSet.contains(orderList[account], id);
    }

    function getOrder(address account, uint256 index) public view returns (uint256) {
        require(index <= getOrderLength(account) - 1, "order index out of bounds");
        return EnumerableSet.at(orderList[account], index);
    }

    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    // ============ Internal Functions ============

    function addOrder(address account, uint256 id) internal returns (bool) {
        require(!isOrderExist(account, id), "order exist");
        return EnumerableSet.add(orderList[account], id);
    }

    function delOrder(address account, uint256 id) internal returns (bool) {
        require(isOrderExist(account, id), "order not exist");
        return EnumerableSet.remove(orderList[account], id);
    }

    function update() internal {
        if (block.timestamp <= lastRewardTime) {
            return;
        }

        if (totalShares == 0) {
            lastRewardTime = block.timestamp;
            return;
        }

        uint256 ts;
        if (block.timestamp >= deadline) {
            if (deadline > lastRewardTime) {
                ts = deadline - lastRewardTime;
            }
        } else {
            ts = block.timestamp - lastRewardTime;
        }

        if (ts > 0) {
            uint256 reward = rewardPerSecond * ts;
            if (totalReward >= reward) {
                totalReward -= reward;
            } else {
                reward = totalReward;
                totalReward = 0;
            }
            accRewardPerShare += reward * 10**18 / totalShares;
            lastRewardTime = block.timestamp;
        }
    }
}