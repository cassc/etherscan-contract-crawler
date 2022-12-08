// SPDX-License-Identifier: MIT
// https://github.com/daomaker/stakevr/blob/master/contracts/StakeVR.sol
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MetaShooterStaker is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint32 constant HUNDRED_PERCENT = 1e3;

    struct Stake {
        bool unstaked;
        uint128 amount;
        uint48 lockTimestamp;
        uint16 lockDays;
        uint16 shareBonus;
        uint16 shareLongBonus;
    }

    IERC20 public stakingToken;
    mapping(address => Stake[]) public stakers;
    address[] public stakerList;
    uint256 public totalShares;
    uint16 public minLockDays;
    uint16 public maxLockDays;
    uint16 public shareBonusPerYear;
    uint16 public shareLongBonusPerYear;

    event EStake(
        address staker,
        uint128 amount,
        uint256 shares,
        uint48 lockTimestamp,
        uint16 lockDays,
        uint16 shareBonus,
        uint16 shareLongBonus,
        uint256 totalShares
    );

    event EUnstake(
        address staker,
        uint stakeIndex,
        uint256 totalShares
    );

    constructor(
        IERC20 _stakingToken,
        uint16 _minLockDays,
        uint16 _maxLockDays,
        uint16 _shareBonusPerYear,
        uint16 _shareLongBonusPerYear
    ) {
        require(address(_stakingToken) != address(0));
        require(_minLockDays <= _maxLockDays, "MetashooterStaker: minLockDays > maxLockDays");
        stakingToken = _stakingToken;
        minLockDays = _minLockDays;
        maxLockDays = _maxLockDays;
        shareBonusPerYear = _shareBonusPerYear;
        shareLongBonusPerYear = _shareLongBonusPerYear;
    }

    function stake(uint128 amount, uint16 lockDays) external nonReentrant {
        require(lockDays >= minLockDays && lockDays <= maxLockDays, "MetashooterStaker: invalid lockDays");
        (uint256 shares, ,) = calculateShares(amount, lockDays);
        totalShares += shares;

        if (stakers[msg.sender].length == 0) {
            stakerList.push(msg.sender);
        }

        stakers[msg.sender].push(Stake(
            false,
            amount,
            uint48(block.timestamp),
            lockDays,
            shareBonusPerYear,
            shareLongBonusPerYear
        ));

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit EStake(msg.sender, amount, shares, uint48(block.timestamp), lockDays, shareBonusPerYear, shareLongBonusPerYear, totalShares);
    }

    function unstake(uint stakeIndex) external nonReentrant {
        require(stakeIndex < stakers[msg.sender].length, "MetashooterStaker: invalid index");
        Stake storage stakeRef = stakers[msg.sender][stakeIndex];
        require(!stakeRef.unstaked, "MetashooterStaker: unstaked already");
        require(stakeRef.lockTimestamp + uint48(stakeRef.lockDays) * 86400 <= block.timestamp, "MetashooterStaker: unstaking too early");

        (uint256 shares, ,) = calculateShares(stakeRef.amount, stakeRef.lockDays);
        totalShares -= shares;
        stakeRef.unstaked = true;
        stakingToken.safeTransfer(msg.sender, stakeRef.amount);
        emit EUnstake(msg.sender, stakeIndex, totalShares);
    }

    function calculateShares(
        uint amount,
        uint lockDays
    ) public view returns (
        uint192 shares,
        uint256 bonus,
        uint256 longTermBonus
    ) {
        return calculateStakeShares(amount, lockDays, shareBonusPerYear, shareLongBonusPerYear);
    }

    function calculateStakeShares(
        uint amount,
        uint lockDays,
        uint16 shareBonus,
        uint16 shareLongBonus
    ) public view returns (
        uint192 shares,
        uint256 bonus,
        uint256 longTermBonus
    ) {
        bonus = amount * lockDays * shareBonus / 365 / HUNDRED_PERCENT;
        longTermBonus = amount * lockDays * lockDays / 1000 * shareLongBonus / 365 / HUNDRED_PERCENT;
        shares = uint192(amount + bonus + longTermBonus);
    }

    function getStakerInfo(
        address stakerAddress
    ) public view returns (
        uint256 totalStakeAmount,
        uint256 totalStakerShares
    ) {
        for (uint i = 0; i < stakers[stakerAddress].length; i++) {
            Stake storage stakeRef = stakers[stakerAddress][i];
            if (stakeRef.unstaked) continue;

            totalStakeAmount += stakeRef.amount;
            (uint256 shares, , ) = calculateShares(stakeRef.amount, stakeRef.lockDays);
            totalStakerShares += shares;
        }
    }

   function setBonus(uint16 shareBonus, uint16  shareLongBonus) public onlyOwner {
        shareBonusPerYear = shareBonus;
        shareLongBonusPerYear = shareLongBonus;
    }

   function setStakingDuration(uint16 _minLockDays, uint16 _maxLockDays) public onlyOwner {
        minLockDays = _minLockDays;
        maxLockDays = _maxLockDays;
    }

    function stakerStakeCount(address stakerAddress) public view returns (uint) {
        return stakers[stakerAddress].length;
    }
}