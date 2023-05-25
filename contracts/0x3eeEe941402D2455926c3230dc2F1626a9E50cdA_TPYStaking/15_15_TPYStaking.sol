// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract TPYStaking is AccessControl {
    /**
     * @notice Info of each pool
     * @param isPaused: is the pool paused
     * @param lockPeriod: stake lock period
     * @param apy: stake yearly interest. Format example: 1050 = 10,5%
     * @param totalStakes: total stakes in this pool
     * @param pauseCheckpoint: pool pause checkpoint
     */
    struct PoolInfo {
        bool isPaused;
        uint256 lockPeriod;
        uint256 apy;
        uint256 totalStakes;
        uint256 pauseCheckpoint;
    }

    /**
     * @notice Info of each stake
     * @param amount: amount of user's stake
     * @param checkpoint: timestamp of user's last action
     * @param releaseCheckpoint: timestamp of passing the lock period
     */
    struct UserStake {
        uint256 amount;
        uint256 checkpoint;
        uint256 releaseCheckpoint;
    }

    ERC20 public immutable tpy;
    uint256 public constant SECONDS_IN_YEAR = 31557600; // 365.25 days
    uint256 public constant REINVEST_PERIOD = 2629800; // 30.4 days
    uint256 public referrerReward = 0; // referrer reward
    uint256 private idCounter; // counter for referral system

    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserStake)) public stakes; // pool ID -> user address -> user stake info

    mapping(uint256 => uint256) public referralToReferrer; // referral ID -> referrer ID
    mapping(address => uint256) public addressToId; // user address -> referral system ID
    mapping(uint256 => address) public idToAddress; // referral system ID -> user address

    event Stake(address indexed user, uint256 indexed pid, uint256 amount);
    event Unstake(address indexed user, uint256 indexed pid, uint256 amount);
    event Restake(address indexed user, uint256 indexed pid, uint256 amount);
    event NewReferral(address referral, address referrer);
    event NewPool(uint256 indexed pid, uint256 apy, uint256 lockPeriod);
    event PausePool(uint256 indexed pid, uint256 pauseCheckpoint);
    event NewReferrerReward(uint256 referrerReward);
    event NewTreasury(address treasury);

    constructor(ERC20 _tpy, address treasury, address admin_) {
        tpy = _tpy;
        idToAddress[0] = treasury;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /**
     * @notice Add new staking pool
     * @param apy_: New staking pool apy
     * @param lockPeriod_: New staking pool lock period
     */
    function addPool(uint256 apy_, uint256 lockPeriod_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(apy_ != 0, "TPYStaking::APY can't be 0");

        poolInfo.push(
            PoolInfo({isPaused: false, lockPeriod: lockPeriod_, apy: apy_, totalStakes: 0, pauseCheckpoint: 0})
        );

        emit NewPool(poolInfo.length - 1, apy_, lockPeriod_);
    }

    /**
     * @notice Change existing staking pool
     * @param pid_: Staking pool ID
     * @param newApy_: Staking pool new apy
     * @param newLockPeriod_: Staking pool new lock period
     */
    function changePool(uint256 pid_, uint256 newApy_, uint256 newLockPeriod_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newApy_ != 0, "TPYStaking::APY can't be 0");

        poolInfo[pid_].apy = newApy_;
        poolInfo[pid_].lockPeriod = newLockPeriod_;
    }

    /**
     * @notice Pause existing staking pool
     * @param pid_: Staking pool ID
     */
    function pausePool(uint256 pid_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!poolInfo[pid_].isPaused, "TPYStaking::Pool already paused");

        poolInfo[pid_].isPaused = true;
        poolInfo[pid_].pauseCheckpoint = getTime();

        emit PausePool(pid_, getTime());
    }

    /**
     * @notice Set referrer system reward
     * @param newReferrerReward_: New % of referrer system reward
     */
    function setReferrerReward(uint256 newReferrerReward_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newReferrerReward_ <= 100, "TPYStaking::Referrer reward should be between 0 and 100");
        referrerReward = newReferrerReward_;

        emit NewReferrerReward(newReferrerReward_);
    }

    /**
     * @notice Set treasury address for referral system
     * @param newTreasury_: New treasury address
     */
    function setTreasuryAddress(address newTreasury_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        idToAddress[0] = newTreasury_;

        emit NewTreasury(newTreasury_);
    }

    /**
     * @notice withdraw stuck tokens
     * @param token_ token for withdraw.
     * @param amount_ amount of tokens.
     */
    function inCaseTokensGetStuck(address token_, uint256 amount_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(tpy) != token_, "TPYStaking::TPY token can't be withdrawn");

        SafeERC20.safeTransfer(IERC20(token_), msg.sender, amount_);
    }

    /**
     * @notice Stake
     * @param pid_: Staking pool ID
     * @param amount_: TPY token amount to stake
     * @param referrerId_: Referrer ID
     */
    function stake(uint256 pid_, uint256 amount_, uint256 referrerId_) external {
        require(!poolInfo[pid_].isPaused, "TPYStaking::Pool is paused");

        UserStake storage userStake = stakes[pid_][msg.sender];

        if (addressToId[msg.sender] == 0) {
            if (idToAddress[referrerId_] == address(0)) {
                referrerId_ = 0;
            }
            idCounter++;
            addressToId[msg.sender] = idCounter;
            idToAddress[idCounter] = msg.sender;
            referralToReferrer[idCounter] = referrerId_;

            emit NewReferral(msg.sender, idToAddress[referrerId_]);
        }

        uint256 userReward = 0;
        if (userStake.amount > 0) {
            userReward = _reinvest(pid_);
        }
        require(
            tpy.balanceOf(address(this)) >= totalStakes() + (userReward * referrerReward) / 100,
            "TPYStaking::Not enough tokens in contract"
        );

        userStake.amount += amount_;
        userStake.checkpoint = getTime();
        userStake.releaseCheckpoint = getTime() + poolInfo[pid_].lockPeriod;
        poolInfo[pid_].totalStakes += amount_;

        emit Stake(msg.sender, pid_, amount_);

        tpy.transferFrom(msg.sender, address(this), amount_);
        tpy.transfer(userReferrer(msg.sender), (userReward * referrerReward) / 100);
    }

    /**
     * @notice Unstake
     * @param pid_: Staking pool ID
     * @param amount_: TPY token amount to unstake
     */
    function unstake(uint256 pid_, uint256 amount_) external {
        UserStake storage userStake = stakes[pid_][msg.sender];
        require(userStake.releaseCheckpoint <= getTime(), "TPYStaking::Lock period don't passed!");
        require(userStake.amount != 0, "TPYStaking::No stake");

        uint256 userReward = _reinvest(pid_);

        amount_ = amount_ > userStake.amount ? userStake.amount : amount_;

        require(
            tpy.balanceOf(address(this)) >= totalStakes() + (userReward * referrerReward) / 100,
            "TPYStaking::Not enough tokens in contract"
        );

        if (amount_ == userStake.amount) {
            delete stakes[pid_][msg.sender];
        } else {
            userStake.amount -= amount_;
            userStake.checkpoint = getTime();
        }
        poolInfo[pid_].totalStakes -= amount_;

        emit Unstake(msg.sender, pid_, amount_);

        tpy.transfer(msg.sender, amount_);
        tpy.transfer(userReferrer(msg.sender), (userReward * referrerReward) / 100);
    }

    /**
     * @notice Emergency unstake
     * @param pid_: Staking pool ID
     */
    function emergencyUnstake(uint256 pid_) external {
        UserStake memory userStake = stakes[pid_][msg.sender];
        require(userStake.releaseCheckpoint <= getTime(), "TPYStaking::Lock period don't passed!");
        require(userStake.amount != 0, "TPYStaking::No stake");

        uint256 amount = userStake.amount;
        poolInfo[pid_].totalStakes -= amount;
        delete stakes[pid_][msg.sender];

        emit Unstake(msg.sender, pid_, amount);

        tpy.transfer(msg.sender, amount);
    }

    /**
     * @notice Return user referrer address
     * @param user_: referral address
     */
    function userReferrer(address user_) public view returns (address) {
        return idToAddress[referralToReferrer[addressToId[user_]]];
    }

    /**
     * @notice Return total stakes in all pools
     */
    function totalStakes() public view returns (uint256 amount) {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            amount += poolInfo[i].totalStakes;
        }
    }

    /**
     * @notice Get current amount of user's stake including rewards
     * @param pid_: Staking pool ID
     * @param user_: User's address
     */
    function stakeOfAuto(uint256 pid_, address user_) public view returns (uint256 result) {
        UserStake memory userStake = stakes[pid_][user_];
        PoolInfo memory pool = poolInfo[pid_];

        result = userStake.amount;
        if (result <= 0) {
            return result;
        }

        uint256 time = pool.isPaused ? pool.pauseCheckpoint : getTime();
        uint256 passedPeriods = (time - userStake.checkpoint) / REINVEST_PERIOD;

        uint256 p1 = _compound(result, pool.apy, SECONDS_IN_YEAR / REINVEST_PERIOD, passedPeriods);
        uint256 p2 = _compound(result, pool.apy, SECONDS_IN_YEAR / REINVEST_PERIOD, passedPeriods + 1);

        // slither-disable-next-line divide-before-multiply
        result =
            p1 +
            (((time - (passedPeriods * REINVEST_PERIOD + userStake.checkpoint)) * (p2 - p1)) / REINVEST_PERIOD);
    }

    function getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice reinvest user's rewards and change storage
     */
    function _reinvest(uint256 pid_) private returns (uint256 userReward) {
        UserStake storage userStake = stakes[pid_][msg.sender];
        PoolInfo storage pool = poolInfo[pid_];

        userReward = stakeOfAuto(pid_, msg.sender) - userStake.amount;

        userStake.amount += userReward;
        userStake.checkpoint = pool.isPaused ? pool.pauseCheckpoint : getTime();
        pool.totalStakes += userReward;

        emit Restake(msg.sender, pid_, userReward);
    }

    /**
     * @notice Calculate compound ROI
     * @param principal_: User stake amount
     * @param n_: Number of passed periods
     */
    function _compound(
        uint256 principal_,
        uint256 apy_,
        uint256 periodsInYear_,
        uint256 n_
    ) private pure returns (uint256) {
        return
            ABDKMath64x64.mulu(
                ABDKMath64x64.pow(
                    ABDKMath64x64.add(ABDKMath64x64.fromUInt(1), ABDKMath64x64.divu(apy_, periodsInYear_ * 10000)),
                    n_
                ),
                principal_
            );
    }
}