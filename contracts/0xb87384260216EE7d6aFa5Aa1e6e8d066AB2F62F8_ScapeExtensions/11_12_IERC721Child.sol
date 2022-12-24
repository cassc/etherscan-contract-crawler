// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional child extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *
 * A child token does not store it's own token balances and does not support
 * minting, transfer, approval. All view methods are passed along to the
 * parent contract.
 */
interface IERC721Child is IERC721 {
    error ERC721Child__InvalidCaller();
    error ERC721Child__InvalidArgument();
    error ERC721Child__NonExistentToken();
    error ERC721Child__ApprovalNotSupported();
    error ERC721Child__TransferNotSupported();
    error ERC721Child__MaxChildContractsReached();

    /**
     * @dev Returns the parent collection.
     */
    function parent() external view returns (address);

    /**
     * @dev Update token ownership from by calling it from the parent contract.
     *
     * Emits a {Transfer} event.
     */
    function update(
        address from,
        address to,
        uint256 tokenId
    ) external;
}