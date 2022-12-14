// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

/**
 * @dev
 */
interface IERC1155Token {

    struct ERC1155Token {
        string uid;
        uint256 tokenId;
        string name;
        uint256 maxSupply;
        address royaltyReceiver;
        address primaryReceiver;
        uint8 royaltyPercentage;
    }

}