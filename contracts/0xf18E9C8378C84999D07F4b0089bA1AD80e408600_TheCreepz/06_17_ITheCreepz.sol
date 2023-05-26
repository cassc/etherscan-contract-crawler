// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

/// @title OniiChain NFTs Interface
interface ITheCreepz {
    /// @notice Details about the Onii
    struct Creepz {
        uint8 bgColor1;
        uint8 bgColor2;
        uint8 bg;
        uint8 bgFill;
        uint8 bgAnim;
        uint8 bgLen;
        //
        uint8 body;
        uint8 bodyColor1;
        uint8 bodyColor2;
        //
        uint8 face;
        uint8 faceColor1;
        uint8 faceColor2;
        uint8 faceAnim;
        //
        uint8 typeEye;
        uint8 eyes;
        uint8 pupils;
        //
        uint8 access;
        //
        bool original;
        uint256 timestamp;
        address creator;
    }

    /// @notice Returns the details associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the Onii
    /// @return detail memory
    function details(uint256 tokenId) external view returns (Creepz memory detail);
}