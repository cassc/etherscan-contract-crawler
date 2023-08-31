// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721} from "./IERC721.sol";

/// @title The interface for {AdoptAHyphen}
interface IAdoptAHyphen {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when a token hasn't been minted.
    error TokenUnminted();

    // -------------------------------------------------------------------------
    // Immutable storage
    // -------------------------------------------------------------------------

    /// @return The Hyphen NFT contract.
    function hyphenNft() external view returns (IERC721);

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Mints a token to the sender in exchange for the hyphen NFT (the
    /// NFT gets transferred into this contract, and it can never be transferred
    /// out).
    /// @dev `msg.sender` must have approvals set to `true` on the hyphen NFT
    /// with the operator as this contract's address.
    function mint(uint256 _tokenId) external;

    // -------------------------------------------------------------------------
    // Metadata
    // -------------------------------------------------------------------------

    /// @return The contract URI for this contract.
    function contractURI() external view returns (string memory);
}