// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

/// @dev Staking tokens. The reward is supposed
///   to be given out by some other mechanism using
///   weighted total stake, user stake amount and rate.
/// @title IIqStaking
/// @author gotbit
interface IIqStaking2 {
    struct Class {
        uint8 rate; // rights multiplicator 5x 3x etc
        uint64 period;
    }

    struct Stake {
        uint256 amount;
        uint64 startTimestamp;
        Class class;
    }

    /// @dev Returns address of staker.
    /// @param i Index of staker.
    function stakers(uint256 i) external view returns (address);

    /// @dev Returns the total amount of stakers
    function stakersLength() external view returns (uint256);

    /// @dev Returns sum of all stakes multiplied by their rate.
    function weightedTotalSupply() external view returns (uint256);

    struct UserSharesOutput {
        address user;
        uint256 share;
    }

    /// @dev Returns part of an array of stakers along with
    ///   their share in weightedTotalSupply().
    /// @param offset Offset in stakers array.
    /// @param size Maximum amount of stakers to return.
    function userShares(uint256 offset, uint256 size)
        external
        view
        returns (UserSharesOutput[] memory);

    /// @dev Stake `amount` of token with class `classId` params.
    /// @param amount Amount of tokens to stake.
    /// @param classId ID of stake preset/class
    function stake(uint256 amount, uint256 classId) external;

    /// @dev Unstake all tokens staked by the caller.
    function unstake() external;

    /// @dev Set stake classes.
    /// @param classes_ Array of classes. A class defines the stake period and reward rate.
    function setClasses(Class[] memory classes_) external;
}

interface IIqStaking is IIqStaking2 {
    /// @dev Returns information about user stake.
    /// @param user User address.
    function stakes(address user) external view returns (Stake calldata);
}