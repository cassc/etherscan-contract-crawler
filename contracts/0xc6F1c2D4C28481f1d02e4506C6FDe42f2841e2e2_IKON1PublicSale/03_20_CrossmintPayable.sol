// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

/**
 * Crossmint purchase library - allows Crossmint to call purchase function to mint pieces of a collection.
 */
abstract contract CrossmintPayable is AdminControl {
    event PurchaseCrossmint(bytes32 indexed nonce);

    address public crossmintAddress =
        0xdAb1a1854214684acE522439684a145E62505233;

    /**
     * @dev Modifier for Crossmint only purchase function
     */
    modifier onlyCrossmint() {
        require(msg.sender == crossmintAddress, "Only callable by Crossmint");
        _;
    }

    /**
     * @dev Set the crossmint address
     */
    function setCrossmintAddress(address crossmintAddress_)
        external
        adminRequired
    {
        crossmintAddress = crossmintAddress_;
    }
}