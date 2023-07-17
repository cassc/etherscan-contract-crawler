// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {PRBMathUD60x18} from "@prb/math/contracts/PRBMathUD60x18.sol";

/// @title Staking (modified from Origin Staking for MAV)
/// @author Origin Staking author: Daniel Von Fange
/// @notice Provides staking, vote power history, vote delegation.
///
/// The balance received for staking (and thus the voting power) goes up
/// exponentially by the end of the staked period.
contract VotingEscrow is ERC20Votes, ReentrancyGuard {
    using SafeERC20 for IERC20;
    // 1. Core Storage
    uint256 public immutable epoch; // timestamp
    uint256 public constant minStakeDuration = 1 weeks; // in seconds
    uint256 public constant maxStakeDuration = 4 * (365 days); // in seconds

    // 2. Staking and Lockup Storage
    uint256 public constant YEAR_BASE = 1.5e18;
    struct Lockup {
        uint128 amount;
        uint128 end;
        uint256 points;
    }
    mapping(address => Lockup[]) public lockups;

    IERC20 public immutable mav; // Must not allow reentrancy

    // Events
    event Stake(address indexed user, uint256 lockupId, uint256 amount, uint256 end, uint256 points);
    event Unstake(address indexed user, uint256 lockupId, uint256 amount, uint256 end, uint256 points);

    // 1. Core Functions

    constructor(IERC20 mav_) ERC20("Voting Escrow MAV", "veMAV") ERC20Permit("veMAV") {
        mav = mav_;
        epoch = block.timestamp;
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("Staking: Transfers disabled");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("Staking: Transfers disabled");
    }

    // 2. Staking and Lockup Functions

    /// @notice Count of number of lockups for a staker
    /// @param staker address of staker
    function lockupCount(address staker) external view returns (uint256 count) {
        return lockups[staker].length;
    }

    /// @notice Stake mav to an address that may not be the same as the
    /// sender of the funds. This can be used to give staked funds to someone
    /// else.
    ///
    /// If staking before the start of staking (epoch), then the lockup start
    /// and end dates are shifted forward so that the lockup starts at the
    /// epoch.
    ///
    /// @param amount mav to lockup in the stake
    /// @param duration in seconds for the stake
    /// @param to address to receive ownership of the stake
    function stake(uint256 amount, uint256 duration, address to) external {
        _stake(amount, duration, to, false);
    }

    /// @notice Stake mav
    ///
    /// If staking before the start of staking (epoch), then the lockup start
    /// and end dates are shifted forward so that the lockup starts at the
    /// epoch.
    ///
    /// @notice Stake mav for myself.
    /// @param amount mav to lockup in the stake
    /// @param duration in seconds for the stake
    /// @param doDelegation is bool; if true, delegate to sender
    function stake(uint256 amount, uint256 duration, bool doDelegation) external {
        _stake(amount, duration, msg.sender, doDelegation);
    }

    /// @dev Internal method used for public staking
    /// @param amount mav to lockup in the stake
    /// @param duration in seconds for the stake
    /// @param to address to receive ownership of the stake
    /// @param doDelegation is bool; if true and to is sender, delegate to sender
    function _stake(uint256 amount, uint256 duration, address to, bool doDelegation) internal nonReentrant {
        require(to != address(0), "Staking: To the zero address");
        require(amount > 0, "Staking: Not enough");

        // duration checked inside previewPoints
        (uint256 points, uint256 end) = previewPoints(amount, duration);
        lockups[to].push(Lockup({amount: SafeCast.toUint128(amount), end: SafeCast.toUint128(end), points: points}));
        _mint(to, points);

        if (to == msg.sender && doDelegation) _delegate(to, to);

        mav.safeTransferFrom(msg.sender, address(this), amount); // Important that it's sender

        emit Stake(to, lockups[to].length - 1, amount, end, points);
    }

    /// @notice Collect staked mav for a lockup.
    /// @param lockupId the id of the lockup to unstake
    function unstake(uint256 lockupId) external nonReentrant {
        Lockup memory lockup = lockups[msg.sender][lockupId];
        uint256 amount = lockup.amount;
        uint256 end = lockup.end;
        uint256 points = lockup.points;

        require(block.timestamp >= end, "Staking: End of lockup not reached");
        require(end != 0, "Staking: Already unstaked this lockup");

        delete lockups[msg.sender][lockupId]; // Keeps empty in array, so indexes are stable

        _burn(msg.sender, points);

        mav.safeTransfer(msg.sender, amount);

        emit Unstake(msg.sender, lockupId, amount, end, points);
    }

    /// @notice Extend a stake lockup for additional points.
    ///
    /// The stake end time is computed from the current time + duration, just
    /// like it is for new stakes. So a new stake for seven days duration and
    /// an old stake extended with a seven days duration would have the same
    /// end.
    ///
    /// If an extend is made before the start of staking, the start time for
    /// the new stake is shifted forwards to the start of staking, which also
    /// shifts forward the end date.
    ///
    /// @param lockupId the id of the old lockup to extend
    /// @param duration number of seconds from now to stake for
    /// @param amount of additional mav to lockup. amount can be zero
    /// @param doDelegation is bool; if true, delegate to sender
    function extend(uint256 lockupId, uint256 duration, uint256 amount, bool doDelegation) external nonReentrant {
        // duration checked inside previewPoints
        Lockup memory lockup = lockups[msg.sender][lockupId];
        uint256 oldAmount = lockup.amount;
        uint256 newAmount = oldAmount + amount;
        uint256 oldEnd = lockup.end;
        uint256 oldPoints = lockup.points;

        (uint256 newPoints, uint256 newEnd) = previewPoints(newAmount, duration);
        require(newEnd > oldEnd, "Staking: New lockup must be longer");

        lockup.end = SafeCast.toUint128(newEnd);
        lockup.points = newPoints;
        if (amount != 0) lockup.amount = SafeCast.toUint128(newAmount);

        lockups[msg.sender][lockupId] = lockup;
        _mint(msg.sender, newPoints - oldPoints);

        if (doDelegation) _delegate(msg.sender, msg.sender);

        if (amount != 0) mav.safeTransferFrom(msg.sender, address(this), amount); // Important that it's sender

        emit Unstake(msg.sender, lockupId, oldAmount, oldEnd, oldPoints);
        emit Stake(msg.sender, lockupId, newAmount, newEnd, newPoints);
    }

    /// @notice Preview the number of points that would be returned for the
    /// given amount and duration.
    ///
    /// @param amount mav to be staked
    /// @param duration number of seconds to stake for
    /// @return points staking points that would be returned
    /// @return end staking period end date
    function previewPoints(uint256 amount, uint256 duration) public view returns (uint256, uint256) {
        require(duration >= minStakeDuration, "Staking: Too short");
        require(duration <= maxStakeDuration, "Staking: Too long");
        uint256 start = block.timestamp > epoch ? block.timestamp : epoch;
        uint256 end = start + duration;
        uint256 endYearpoc = Math.mulDiv((end - epoch), 1e18, 365 days);
        uint256 multiplier = PRBMathUD60x18.pow(YEAR_BASE, endYearpoc);
        return (Math.mulDiv(amount, multiplier, 1e18), end);
    }
}