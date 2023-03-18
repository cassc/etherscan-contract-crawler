/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title NFT Token URI provider
 * @author Theori, Inc.
 * @notice Outsourced tokenURI provider for NFT/SBT tokens
 */
interface ITokenURI {
    /**
     * @notice Get the URI for the given token
     * @param tokenID the unique ID for the token
     * @return the string of the URI
     * @dev when called with an invalid tokenID, this may revert,
     *      or it may return invalid output
     */
    function tokenURI(uint256 tokenID) external view returns (string memory);
}