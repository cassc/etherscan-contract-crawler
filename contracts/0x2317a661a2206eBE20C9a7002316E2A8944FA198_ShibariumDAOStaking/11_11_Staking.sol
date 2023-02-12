// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./RewardsPool.sol";

contract ShibariumDAOStaking is ReentrancyGuard {
    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    // totalRewards and rewards are in RewardPoints (refer to the right function)
    uint256 public totalRewards;

    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public rewards;

    IERC20 public immutable SHIBDAO;
    IERC20 public immutable SHIBGOV;

    uint256 public constant LOCK_TIME = 30 days;

    RewardsPool public immutable POOL_SHIB;
    RewardsPool public immutable POOL_BONE;

    address immutable TEAM;

    event StakeAdded(address staker, uint256 amount, uint256 lockTime);
    event StakeRemoved(address staker, uint256 amount, uint256 lockTime);

    constructor(
        address shib,
        address bone,
        address shibdao,
        address shibgov
    ) ReentrancyGuard() {
        POOL_SHIB = new RewardsPool(shib, address(this), msg.sender);
        POOL_BONE = new RewardsPool(bone, address(this), msg.sender);
        SHIBDAO = IERC20(shibdao);
        SHIBGOV = IERC20(shibgov);

        TEAM = msg.sender;
    }

    function addStake(uint256 amount) external nonReentrant {
        stakes[msg.sender].push(Stake(amount, block.timestamp));
        emit StakeAdded(msg.sender, amount, block.timestamp);

        bool success = SHIBDAO.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        bool successGov = SHIBGOV.transfer(msg.sender, amount);
        require(successGov, "Transfer failed");
    }

    function removeStake(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= getFreeStake(), "Not enough free stake");

        claimRewards();

        uint256 remaining = amount;
        Stake[] storage userStakes = stakes[msg.sender];

        for (uint256 i = 0; i < userStakes.length; i++) {
            if (remaining == 0) {
                break;
            }

            uint256 stakeAmount = userStakes[i].amount;
            uint256 amountToRemove = stakeAmount > remaining
                ? remaining
                : stakeAmount;
            removeStakeIndexed(i, amountToRemove);
            remaining -= amountToRemove;
        }
    }

    function claimRewards() public nonReentrant {
        uint256 myTotalRewardPoints = calculateRewardPoints();
        uint256 newRewardPoints = myTotalRewardPoints - rewards[msg.sender];

        rewards[msg.sender] = myTotalRewardPoints;
        totalRewards += newRewardPoints;

        POOL_SHIB.sendRewards(msg.sender, newRewardPoints, 10**18);
        POOL_BONE.sendRewards(msg.sender, newRewardPoints, 10**18);
    }

    function removeStakeIndexed(uint256 index, uint256 amount) internal {
        Stake storage stake = stakes[msg.sender][index];

        require(stake.startTime + LOCK_TIME <= block.timestamp, "Stake locked");
        require(stake.amount >= amount, "Not enough stake");

        stake.amount -= amount;

        emit StakeRemoved(msg.sender, amount, block.timestamp);

        bool success = SHIBDAO.transfer(msg.sender, amount);
        require(success, "Transfer failed");

        bool successGov = SHIBGOV.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(successGov, "Transfer failed");
    }

    function getFreeStake() public view returns (uint256 freeStake) {
        for (uint256 i = 0; i < stakes[msg.sender].length; i++) {
            if (
                stakes[msg.sender][i].startTime + LOCK_TIME <= block.timestamp
            ) {
                freeStake += stakes[msg.sender][i].amount;
            }
        }
    }

    function calculateRewardPoints() public view returns (uint256) {
        uint256 rewardPoints = 0;
        Stake[] storage myStakes = stakes[msg.sender];

        for (uint256 i = 0; i < myStakes.length; i++) {
            rewardPoints += calculareRewardPointsIndexed(myStakes[i]);
        }

        return rewardPoints;
    }

    function calculareRewardPointsIndexed(Stake storage stake)
        internal
        view
        returns (uint256)
    {
        uint256 stakeTime = block.timestamp - stake.startTime;
        uint256 timePct = (10**18) -
            (10**18) /
            (2**(stakeTime / LOCK_TIME / 12));

        uint256 supplyPct = (stake.amount * (10**18)) / (SHIBDAO.totalSupply());

        return (timePct * supplyPct) / (10**18);
    }

    function getPoolShib() external view returns (address) {
        return address(POOL_SHIB);
    }

    function getPoolBone() external view returns (address) {
        return address(POOL_BONE);
    }

    function getStakes(address user)
        external
        view
        returns (Stake[] memory userStakes)
    {
        return stakes[user];
    }
}