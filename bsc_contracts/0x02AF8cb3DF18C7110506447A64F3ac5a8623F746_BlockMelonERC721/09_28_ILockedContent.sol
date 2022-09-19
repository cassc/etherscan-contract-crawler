// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILockedContent {
    /**
     * @notice Returns the locked content of the given `tokenId`.
     */
    function getLockedContent(uint256 tokenId)
        external
        view
        returns (string memory);
}