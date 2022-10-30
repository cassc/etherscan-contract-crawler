// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChallenge {
    /// Execute a given solution, using the seed to generate inputs. The actual
    /// implementation is specific to the challenge.
    /// @return The amount of gas consumed by the solution.
    function run(address target, uint256 seed) external view returns (uint32);

    /// @return An SVG snippet, which is embedded in the main NFT.
    function svg(uint256 tokenId) external view returns (string memory);

    /// @return The name of the challenge.
    function name() external view returns (string memory);

    /// @return The description of the challenge.
    /// @notice Should not have line breaks.
    function description() external view returns (string memory);
}