// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IMintingModule {
    /// @dev Called by original contract to return how many tokens sender can mint
    /// @notice if performing storage updates, good practice to check that msg.sender is original contract
    function canMint(
        address minter,
        uint256 value,
        uint256[] calldata tokenIds,
        uint256[] calldata mintAmounts,
        bytes32[] calldata proof,
        bytes calldata data
    ) external returns (uint256);
}