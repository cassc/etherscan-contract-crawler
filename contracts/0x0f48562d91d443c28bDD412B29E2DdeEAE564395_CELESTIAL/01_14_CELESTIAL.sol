// SPDX-License-Identifier: MIT

/// @title CELESTIAL
/// @author transientlabs.xyz

pragma solidity 0.8.14;

import "ERC721TLCreator.sol";

contract CELESTIAL is ERC721TLCreator {

    /**
    *   @param royaltyRecipient is the royalty recipient
    *   @param royaltyPercentage is the royalty percentage to set
    *   @param admin is the admin address
    */
    constructor (
        address royaltyRecipient,
        uint256 royaltyPercentage,
        address admin
    )
    ERC721TLCreator("CELESTIAL", "CSTL", royaltyRecipient, royaltyPercentage, admin)
    {}

}