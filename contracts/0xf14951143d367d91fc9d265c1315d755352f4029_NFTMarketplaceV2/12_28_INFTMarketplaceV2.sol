// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../order/LibOrder.sol";

import "./INFTMarketplace.sol";

interface INFTMarketplaceV2 is INFTMarketplace {
    /// @dev Emitted when buyer cancels the bid for the auction
    /// Because he previously signed that order with his wallet, only way to cancel it is to tell the smart contract
    /// that that signature is no longer valid
    event Cancel(LibOrder.Order order);
    /// @dev Emitted when the orders match
    event Match(address indexed nftAddress, uint256 indexed tokenId, address indexed buyer);

    // Admin only

    /// @notice Unpause smart contract
    function unpause() external;

    /// @notice Pause smart contract
    function pause() external;

    // ---------------------------------------------------------------------------------------

    // Marketplace wallet only

    /// @notice Intended to be called by the whitelisted marketplace account
    /// Used for NFT auctions
    /// @dev Seller needs to approve NFT to this contract
    /// @dev NFT Selller is the first parameter. Buyer needs to approve ERC20 token to this contract.
    /// Seller needs to approve ERC721 Token to this contract.
    /// @param makerOrder Seller's order
    /// @param makerSignature Seller's signature EIP712
    /// @param takerOrder Buyer's order
    /// @param takerSignature Buyer's signature EIP712
    function matchOrders(
        LibOrder.Order calldata makerOrder,
        bytes calldata makerSignature,
        LibOrder.Order calldata takerOrder,
        bytes calldata takerSignature
    ) external;

    // ---------------------------------------------------------------------------------------

    /// @notice Cancel order (auctions only)
    function cancelOrder(LibOrder.Order calldata order) external;
}