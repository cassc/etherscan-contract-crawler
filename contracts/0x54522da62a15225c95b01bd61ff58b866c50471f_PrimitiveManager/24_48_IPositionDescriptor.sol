// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

/// @title   Interface of PositionDescriptor contract
/// @author  Primitive
interface IPositionDescriptor {
    /// VIEW FUNCTIONS ///

    /// @notice  Returns the address of the PositionRenderer contract
    function positionRenderer() external view returns (address);

    /// @notice         Returns the metadata of a position token
    /// @param engine   Address of the PrimitiveEngine contract
    /// @param tokenId  Id of the position token (pool id)
    /// @return         Metadata as a base64 encoded JSON string
    function getMetadata(address engine, uint256 tokenId) external view returns (string memory);
}