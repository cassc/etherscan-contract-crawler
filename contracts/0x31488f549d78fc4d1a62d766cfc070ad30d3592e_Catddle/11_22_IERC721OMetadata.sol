// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Metadata extension of the ERC721-O (Omnichain Non-Fungible Token standard)
 */
interface IERC721OMetadata {
    /**
     * @dev Returns the address of cross chain endpoint
     */
    function endpoint() external view returns (address);

    /**
     * @dev Returns the remote trusted contract address on chain `chainId`.
     */
    function remotes(uint16 chainId) external view returns (bytes memory);
}