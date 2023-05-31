// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Required interface of an Registry compliant contract.
 */
interface INFTRegistry {
    /**
     * @dev Emitted when address trying to transfer is not allowed on the registry
     */
    error TransferNotAllowed(address from, address to, uint256 tokenId);

    /**
     * @dev Checks whether `operator` is valid on the registry; let the registry
     * decide across both allow and blocklists.
     */
    function isAllowedOperator(address operator) external view returns (bool);
}