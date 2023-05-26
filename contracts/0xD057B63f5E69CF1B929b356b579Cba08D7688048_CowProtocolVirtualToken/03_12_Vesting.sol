// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

import "../vendored/libraries/Math.sol";

import "../interfaces/VestingInterface.sol";

/// @dev The vesting logic for distributing the COW token
/// @title Vesting Logic
/// @author CoW Protocol Developers
contract Vesting is VestingInterface {
    /// @dev The timestamp of the official vesting start. This value is shared
    /// between all participants.
    uint256 public immutable vestingStart;
    /// @dev How long it will take for all vesting to be completed. It is set to
    /// four years.
    uint256 public constant VESTING_PERIOD_IN_SECONDS = 4 * 365 days + 1 days;

    /// @dev Stores the amount of vesting that the user has already vested.
    mapping(address => uint256) public vestedAllocation;
    /// @dev Stores the maximum amount of vesting available to each user. This
    /// is exactly the total amount of vesting that can be converted after the
    /// vesting period is completed.
    mapping(address => uint256) public fullAllocation;

    /// @dev Stores a bit indicating whether a vesting is cancelable
    /// Important: This implementaiton implies that there can not be a
    /// cancelable and non-cancelable vesting in parallel
    mapping(address => bool) public isCancelable;

    /// @dev Event emitted when a new vesting position is added. The amount is
    /// the additional amount that can be vested at the end of the
    /// claiming period.
    event VestingAdded(address indexed user, uint256 amount, bool isCancelable);
    /// @dev Event emitted when a vesting position is canceled. The amount is
    /// the number of remaining vesting that will be given to the beneficiary.
    event VestingStopped(
        address indexed user,
        address freedVestingBeneficiary,
        uint256 amount
    );
    /// @dev Event emitted when the users claims (also partially) a vesting
    /// position.
    event Vested(address indexed user, uint256 amount);

    /// @dev Error returned when trying to stop a claim that is not cancelable.
    error VestingNotCancelable();

    constructor() {
        vestingStart = block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /// @inheritdoc VestingInterface
    function addVesting(
        address user,
        uint256 vestingAmount,
        bool isCancelableFlag
    ) internal override {
        if (isCancelableFlag) {
            // if one cancelable vesting is made, it converts all vestings into cancelable ones
            isCancelable[user] = isCancelableFlag;
        }
        fullAllocation[user] += vestingAmount;
        emit VestingAdded(user, vestingAmount, isCancelableFlag);
    }

    /// @inheritdoc VestingInterface
    function shiftVesting(address user, address freedVestingBeneficiary)
        internal
        override
        returns (uint256 accruedVesting)
    {
        if (!isCancelable[user]) {
            revert VestingNotCancelable();
        }
        accruedVesting = vest(user);
        uint256 userFullAllocation = fullAllocation[user];
        uint256 userVestedAllocation = vestedAllocation[user];
        fullAllocation[user] = 0;
        vestedAllocation[user] = 0;
        fullAllocation[freedVestingBeneficiary] += userFullAllocation;
        vestedAllocation[freedVestingBeneficiary] += userVestedAllocation;
        emit VestingStopped(
            user,
            freedVestingBeneficiary,
            userFullAllocation - userVestedAllocation
        );
    }

    /// @inheritdoc VestingInterface
    function vest(address user)
        internal
        override
        returns (uint256 newlyVested)
    {
        newlyVested = newlyVestedBalance(user);
        vestedAllocation[user] += newlyVested;
        emit Vested(user, newlyVested);
    }

    /// @dev Assuming no conversions has been done by the user, calculates how
    /// much vesting can be converted at this point in time.
    /// @param user The user for whom the result is being calculated.
    /// @return How much vesting can be converted if no conversions had been
    /// done before.
    function cumulativeVestedBalance(address user)
        public
        view
        returns (uint256)
    {
        return
            (Math.min(
                block.timestamp - vestingStart, // solhint-disable-line not-rely-on-time
                VESTING_PERIOD_IN_SECONDS
            ) * fullAllocation[user]) / (VESTING_PERIOD_IN_SECONDS);
    }

    /// @dev Calculates how much vesting can be converted at this point in time.
    /// Unlike `cumulativeVestedBalance`, this function keeps track of previous
    /// conversions.
    /// @param user The user for whom the result is being calculated.
    /// @return How much vesting can be converted.
    function newlyVestedBalance(address user) public view returns (uint256) {
        return cumulativeVestedBalance(user) - vestedAllocation[user];
    }
}