// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13;

/// @title A contract that resolves URIs based on token id for ERC721 contracts
interface IURIResolver {

    /// @notice See {ERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) external view returns (string memory);

}