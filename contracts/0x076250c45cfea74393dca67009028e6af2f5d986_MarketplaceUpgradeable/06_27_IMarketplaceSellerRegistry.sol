// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMarketplaceSellerRegistry is IERC165 {

    // Events
    event SellerAdded(address requestor, address seller);
    event SellerRemoved(address requestor, address seller);

    /**
     *  @dev Check if seller is authorized
     *
     *  @param seller         Address of seller
     *  @param data           Additional data needed to verify
     */
    function isAuthorized(address seller, bytes calldata data) external view returns(bool);

}