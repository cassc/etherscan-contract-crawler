//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IRenderer
/// @author Simon Fremaux (@dievardump)
interface IRenderer {
    /// @dev Rendering function;
    /// @param name the seedling name
    /// @param tokenId the tokenId
    /// @param seed the seed
    /// @return the json
    function render(
        string memory name,
        uint256 tokenId,
        bytes32 seed
    ) external pure returns (string memory);
}