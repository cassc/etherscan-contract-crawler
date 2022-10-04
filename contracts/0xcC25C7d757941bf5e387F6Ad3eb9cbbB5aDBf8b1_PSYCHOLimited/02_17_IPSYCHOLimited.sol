// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

/// @title PSYCHO Limited
/// @notice A network of fashionable (limited) avatars
interface IPSYCHOLimited {
    /// @notice Set custom json extension for avatar
    /// @param _avatarId designated json extension
    /// @param _extension should not have {} in json
    /// @dev Requires minimum `fee(1)`
    function extension(uint256 _avatarId, string memory _extension)
        external
        payable;

    /// @notice Generation and extension fee
    /// @param _quantity multiplied by generate quantity or 1 for extension
    /// @return Wei fee
    function fee(uint256 _quantity) external view returns (uint256);

    /// @notice Available avatars to generate
    /// @return Avatar stock
    function stock() external view returns (uint256);

    /// @notice Generates up to 1001 avatars
    /// @param _quantity max 20 per transaction
    /// @dev Requires minimum `fee(_quantity)` and `generative() == true`
    function generate(uint256 _quantity) external payable;

    /// @notice Destroy an avatar
    /// @param _avatarId to destroy
    /// @dev Subtracts the avatar generation counter by 1
    function destroy(uint256 _avatarId) external;
}