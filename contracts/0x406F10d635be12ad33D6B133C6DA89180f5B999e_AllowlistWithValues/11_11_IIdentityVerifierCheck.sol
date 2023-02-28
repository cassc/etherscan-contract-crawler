// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Implement this interface if you want to have a view function to check
 * whether or not an identity is verified to bid/purchase
 */
interface IIdentityVerifierCheck is IERC165 {

    /**
     *  @dev Check that a buyer is verified to purchase/bid
     *
     *  @param marketplaceAddress   The address of the marketplace
     *  @param listingId            The listingId associated with this verification
     *  @param identity             The identity to verify
     *  @param tokenAddress         The tokenAddress associated with this verification
     *  @param tokenId              The tokenId associated with this verification
     *  @param requestCount         The number of items being requested to purchase/bid
     *  @param requestAmount        The amount being requested
     *  @param requestERC20         The erc20 token address of the amount (0x0 if ETH)
     *  @param data                 Additional data needed to verify
     *
     */
    function checkVerify(address marketplaceAddress, uint40 listingId, address identity, address tokenAddress, uint256 tokenId, uint24 requestCount, uint256 requestAmount, address requestERC20, bytes calldata data) external view returns (bool);
}