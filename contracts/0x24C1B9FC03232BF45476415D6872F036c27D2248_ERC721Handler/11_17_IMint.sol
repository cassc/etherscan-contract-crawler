// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IMint {
    /// @notice overloaded function to be used by ERC721Handler
    function mint(
        address to,
        uint256 tokenId,
        string memory _data
    ) external;
}