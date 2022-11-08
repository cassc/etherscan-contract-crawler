// SPDX-License-Identifier: MIT

/// @title Interface of Perception: Clicker's Edition
/// @author transientlabs.xyz

pragma solidity 0.8.14;

import "ERC721TLMerkle.sol";

contract InterfaceOfPerceptionClickersEdition is ERC721TLMerkle {

    constructor (
        address royaltyRecipient,
        uint256 royaltyPercentage,
        uint256 supply,
        address admin,
        address payout
    )
    ERC721TLMerkle("Interface of Perception: Clicker's Edition", "IPCE", royaltyRecipient, royaltyPercentage, 0, supply, bytes32(0), admin, payout)
    {}

}