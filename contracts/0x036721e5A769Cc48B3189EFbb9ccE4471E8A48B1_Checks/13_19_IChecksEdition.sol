// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChecksEdition {
    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) external;

    /// @dev Returns the owner of the `tokenId` token.
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @dev Returns the approved operator of a specific token.
    function getApproved(uint256 tokenId) external view returns (address operator);

    /// @dev Error when burning unapproved tokens.
    error TransferCallerNotOwnerNorApproved();
}