// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IIkaniV1MetadataController
 * @author Cyborg Labs, LLC
 *
 * @notice Interface for a contract that provides token metadata via tokenURI().
 */
interface IIkaniV1MetadataController {

    function tokenURI(
        uint256 tokenId
    )
        external
        view
        returns (string memory);
}