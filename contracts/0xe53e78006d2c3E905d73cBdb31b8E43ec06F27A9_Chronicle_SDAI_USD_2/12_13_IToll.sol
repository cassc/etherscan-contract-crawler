// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IToll {
    /// @notice Thrown by protected function if caller not tolled.
    /// @param caller The caller's address.
    error NotTolled(address caller);

    /// @notice Emitted when toll granted to address.
    /// @param caller The caller's address.
    /// @param who The address toll got granted to.
    event TollGranted(address indexed caller, address indexed who);

    /// @notice Emitted when toll renounced from address.
    /// @param caller The caller's address.
    /// @param who The address toll got renounced from.
    event TollRenounced(address indexed caller, address indexed who);

    /// @notice Grants address `who` toll.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to grant toll.
    function kiss(address who) external;

    /// @notice Renounces address `who`'s toll.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to renounce toll.
    function diss(address who) external;

    /// @notice Returns whether address `who` is tolled.
    /// @param who The address to check.
    /// @return True if `who` is tolled, false otherwise.
    function tolled(address who) external view returns (bool);

    /// @notice Returns full list of addresses tolled.
    /// @dev May contain duplicates.
    /// @return List of addresses tolled.
    function tolled() external view returns (address[] memory);

    /// @notice Returns whether address `who` is tolled.
    /// @custom:deprecated Use `tolled(address)(bool)` instead.
    /// @param who The address to check.
    /// @return 1 if `who` is tolled, 0 otherwise.
    function bud(address who) external view returns (uint);
}