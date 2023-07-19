// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import './ILaunchpad.sol';

/// @dev The interface has to be separated in
///   this way because of a bug in solc that prevents us
///   from inhereting from it.
///   https://github.com/ethereum/solidity/issues/11826
/// @title IVesting2
/// @author gotbit
interface IVesting2 {
    struct Unlock {
        uint128 datetime;
        uint128 percentage; // 18 digits
    }

    event Claim(address indexed from, uint256 amount);

    /// @dev Allows to get the investment round of this vesting
    /// @return _round investment round (0 = seed, 1 = private, 2 = public)
    function round() external view returns (uint8);

    /// @dev Allows to get the launchpad contract of the project
    /// @return _launchpad the launchpad contract
    function launchpad() external view returns (ILaunchpad);

    /// @dev Allows to get the amount of tokens claimed by a user
    /// @param user the user
    /// @return _claimed the amount of claimed tokens
    function claimed(address user) external view returns (uint256);

    /// @dev Allows the user (caller) to claim their vested tokens
    function claim(address investor) external;

    /// @dev Initializes the vesting contract
    /// @param round_ investment round
    /// @param launchpad_ launchpad contract
    function initialize(
        uint8 round_,
        address launchpad_,
        Unlock[] calldata settings_,
        address router_
    ) external;

    /// @dev Allows to get the amount of tokens unlocked for claiming by the user
    /// @param user the user
    /// @return _unlocked the amount of unlocked tokens
    function unlocked(address user) external view returns (uint256);

    /// @dev Allows the launchpad admin to change vesting settings in real time
    function changeSchedule(Unlock[] calldata) external;

    /// @dev Returns the amount of unlock events
    function scheduleLength() external view returns (uint256);

    /// @dev Returns when the last unlock event will happen
    function vestingEndTime() external view returns (uint256);
}

/// @title IVesting
/// @author gotbit
interface IVesting is IVesting2 {
    /// @dev Returns info about `i`-th unlock event.
    function schedule(uint256 id) external view returns (Unlock calldata);

    /// @dev Returns all unlock events.
    function getSchedule() external view returns (Unlock[] calldata);
}