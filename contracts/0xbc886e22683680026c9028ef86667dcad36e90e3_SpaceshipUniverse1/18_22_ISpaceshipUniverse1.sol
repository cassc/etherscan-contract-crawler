// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IERC5192.sol";

/// @title SpaceshipUniverse1
/// @notice Spaceship NFT for Spacebar Universe 1
/// This contract introduces the concept of "Active Ownership", wherein the user must fulfill
/// certain conditions to gain full ownership of a spaceship NFT.
/// Until these conditions are met, the spaceship is locked and cannot be transferred.
/// For the above purpose, this contract implements ERC5192.
/// Additionally, the Space Factory reserves the right to burn the spaceship under specific conditions (to be defined later).
/// The total circulating supply (minted minus burned) is limited.
interface ISpaceshipUniverse1 is IERC721, IERC5192 {
    /// @notice Mints a new Spaceship. Spaceships are locked by default (also known as Protoships).
    /// @dev Only the space factory contract can call this function.
    /// @param to The address to which the Protoship will be minted.
    /// This should be TBA's address, as the Protoship is initially bound to the TBA.
    function mint(address to) external returns (uint256 tokenId);

    /// @notice Burns a Spaceship.
    /// @dev Only the space factory contract can call this function, and only a Protoship can be burned.
    /// @param tokenId The ID of the Spaceship to burn.
    function burn(uint256 tokenId) external;

    /// @notice Unlocks a Spaceship (i.e., a Protoship becomes Ownership).
    /// @dev Only the space factory contract can call this function. From this point on,
    /// the user fully owns the Spaceship and can transfer it to other users.
    /// @param tokenId The ID of the Spaceship to unlock.
    function unlock(uint256 tokenId) external;

    /// @notice Called when the metadata of a Spaceship is updated.
    /// @dev This function will only emit an event (ERC4906).
    /// @param tokenId The ID of the Spaceship for which to update metadata.
    function updateMetadata(uint256 tokenId) external;

    /// @dev Returns the ID of the next token to be minted.
    function nextTokenId() external returns (uint256);
}