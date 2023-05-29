// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IMembershipRenderer {
    // to be called by frontend to render for a provided membership contract
    function tokenURIOf(address membership, uint256 tokenId)
        external
        view
        returns (string memory);

    // to be called by a ERC721Membership contract
    function tokenURI(uint256 tokenId) external view returns (string memory);
}