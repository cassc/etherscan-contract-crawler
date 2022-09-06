// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721Controller } from "./IERC721Controller.sol";

/**
 * @title ERC721 interface
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Controller {
    /**
     * @notice Get the balance of an owner
     * @param owner The owner's address
     * @return balance The balance amount
     */
    function balanceOf(address owner) external returns (uint256);

    /**
     * @notice Get the owner a token
     * @param tokenId The token id
     * @return owner The owner's address
     */
    function ownerOf(uint256 tokenId) external returns (address);

    /**
     * @notice Transfer a token between addresses
     * @dev Preforms ERC721Receiver check if applicable
     * @param from The token's owner address
     * @param to The recipient address
     * @param tokenId The token id
     * @param data Additional data
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @notice Transfer a token between addresses
     * @dev Preforms ERC721Receiver check if applicable
     * @param from The token's owner address
     * @param to The recipient address
     * @param tokenId The token id
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Transfer a token between addresses
     * @param from The token's owner address
     * @param to The recipient address
     * @param tokenId The token id
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Grant approval to a token
     * @param approved The address to approve
     * @param tokenId The token id
     */
    function approve(address approved, uint256 tokenId) external;

    /**
     * @notice Set operator approval
     * @param operator The operator's address
     * @param approved Whether to grant approval
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @notice Get the approved address of a token
     * @param tokenId The token id
     * @return approved The approved address
     */
    function getApproved(uint256 tokenId) external returns (address);

    /**
     * @notice Query whether the operator is approved for an address
     * @param owner The address to query
     * @param operator The operator's address
     * @return isApproved Whether the operator is approved
     */
    function isApprovedForAll(address owner, address operator) external returns (bool);
}