//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILockLeash.sol";
import "./interfaces/ILandAuction.sol";

contract LockLeash is ILockLeash, Ownable {
    uint256 public immutable AMOUNT_MIN;
    uint256 public immutable AMOUNT_MAX;
    uint256 public immutable DAYS_MIN;
    uint256 public immutable DAYS_MAX;

    IERC20 public immutable LEASH;
    IERC20 public immutable BONE;

    ILandAuction public landAuction;

    bool public isLockEnabled;

    uint256 public totalWeight;
    uint256 public totalBoneRewards;

    struct Lock {
        uint256 amount;
        uint256 startTime;
        uint256 numDays;
        address ogUser;
    }

    mapping(address => Lock) private _lockOf;

    constructor(
        address _leash,
        address _bone,
        uint256 amountMin,
        uint256 amountMax,
        uint256 daysMin,
        uint256 daysMax
    ) {
        LEASH = IERC20(_leash);
        BONE = IERC20(_bone);
        AMOUNT_MIN = amountMin;
        AMOUNT_MAX = amountMax;
        DAYS_MIN = daysMin;
        DAYS_MAX = daysMax;
    }

    function lockInfoOf(address user)
        public
        view
        returns (
            uint256 amount,
            uint256 startTime,
            uint256 numDays,
            address ogUser
        )
    {
        return (
            _lockOf[user].amount,
            _lockOf[user].startTime,
            _lockOf[user].numDays,
            _lockOf[user].ogUser
        );
    }

    function weightOf(address user) public view returns (uint256) {
        return _lockOf[user].amount * _lockOf[user].numDays;
    }

    function extraLeashNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256)
    {
        uint256 currentWeight = weightOf(user);

        if (currentWeight >= targetWeight) {
            return 0;
        }

        return (targetWeight - currentWeight) / _lockOf[user].numDays;
    }

    function extraDaysNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256)
    {
        uint256 currentWeight = weightOf(user);

        if (currentWeight >= targetWeight) {
            return 0;
        }

        return (targetWeight - currentWeight) / _lockOf[user].amount;
    }

    function isWinner(address user) public view returns (bool) {
        return landAuction.winningsBidsOf(user) > 0;
    }

    function unlockAt(address user) public view returns (uint256) {
        Lock memory s = _lockOf[user];

        if (isWinner(user)) {
            return s.startTime + s.numDays * 1 days;
        }

        return s.startTime + 15 days + (s.numDays * 1 days) / 3;
    }

    function setLandAuction(address sale) external onlyOwner {
        landAuction = ILandAuction(sale);
    }

    function addBoneRewards(uint256 rewardAmount) external onlyOwner {
        totalBoneRewards += rewardAmount;
        BONE.transferFrom(msg.sender, address(this), rewardAmount);
    }

    function toggleLockEnabled() external onlyOwner {
        isLockEnabled = !isLockEnabled;
    }

    function lock(uint256 amount, uint256 numDaysToAdd) external {
        require(isLockEnabled, "Locking not enabled");

        Lock storage s = _lockOf[msg.sender];

        uint256 oldWeight = s.amount * s.numDays;

        s.amount += amount;
        require(
            AMOUNT_MIN <= s.amount && s.amount <= AMOUNT_MAX,
            "LEASH amount outside of limits"
        );

        if (s.numDays == 0) {
            // no existing lock
            s.startTime = block.timestamp;
            s.ogUser = msg.sender;
        }

        if (numDaysToAdd > 0) {
            s.numDays += numDaysToAdd;
        }

        uint256 numDays = s.numDays;

        require(
            DAYS_MIN <= numDays && numDays <= DAYS_MAX,
            "Days outside of limits"
        );

        totalWeight += s.amount * s.numDays - oldWeight;
        LEASH.transferFrom(msg.sender, address(this), amount);
    }

    function unlock() external {
        Lock storage s = _lockOf[msg.sender];

        uint256 amount = s.amount;
        uint256 numDays = s.numDays;

        require(amount > 0, "No LEASH locked");
        require(unlockAt(msg.sender) <= block.timestamp, "Not unlocked yet");
        delete _lockOf[msg.sender];

        LEASH.transfer(msg.sender, amount);
        BONE.transfer(
            msg.sender,
            (totalBoneRewards * amount * numDays) / totalWeight
        );
    }

    function transferLock(address newOwner) external {
        require(_lockOf[msg.sender].numDays != 0, "Lock does not exist");
        require(_lockOf[newOwner].numDays == 0, "New owner already has a lock");
        _lockOf[newOwner] = _lockOf[msg.sender];
        delete _lockOf[msg.sender];
    }
}