// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { OERC721_CallerNotOwner } from "../errors/Vault.sol";

/**
 * @title OwnableERC721
 * @author Non-Fungible Technologies, Inc.
 *
 * Uses ERC721 ownership for access control to a set of contracts.
 * Ownership of underlying contract determined by ownership of a token ID,
 * where the token ID converts to an on-chain address.
 */
abstract contract OwnableERC721 {
    // ============================================ STATE ==============================================

    /// @dev The ERC721 token that contract owners should have ownership of.
    address public ownershipToken;

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @notice Specifies the owner of the underlying token ID, derived
     *         from the contract address of the contract implementing.
     *
     * @return ownerAddress         The owner of the underlying token derived from
     *                              the calling address.
     */
    function owner() public view virtual returns (address ownerAddress) {
        return IERC721(ownershipToken).ownerOf(uint256(uint160(address(this))));
    }

    // ============================================ HELPERS =============================================

    /**
     * @dev Set the ownership token - the ERC721 that specified who controls
     *      defined addresses.
     */
    function _setNFT(address _ownershipToken) internal {
        ownershipToken = _ownershipToken;
    }

    /**
     * @dev Similar to Ownable - checks the method is being called by the owner,
     *      where the owner is defined by the token ID in the ownership token which
     *      maps to the calling contract address.
     */
    modifier onlyOwner() {
        if (owner() != msg.sender) revert OERC721_CallerNotOwner(msg.sender);
        _;
    }
}