// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IFoundationNftV1TokenCreator {
    /**
     * @notice Returns the creator's address for a given tokenId.
     */
    function tokenCreator(uint256 tokenId)
        external
        view
        returns (address payable);
}