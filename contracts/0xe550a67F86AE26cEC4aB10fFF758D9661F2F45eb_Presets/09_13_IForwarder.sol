// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/// @author pintak.eth
/// @title Interface for forwarder contract
interface IForwarder {
    /// @notice Execute a coins transfer from the forwarder to the dest address
    function forward(address dest, uint256 value) external;

    /// @notice Execute a ERC20 transfer from the forwarder to the dest address
    function forwardERC20(address token, uint256 value, address dest) external;

    /// @notice Execute a ERC721 transfer from the forwarder to the dest address
    function forwardERC721(address token, uint256 id, address dest) external;

    /// @notice Execute a ERC1155 transfer from the forwarder to the dest address
    function forwardERC1155(address token, uint256 id, uint256 value, address dest) external;
}