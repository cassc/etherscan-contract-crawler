// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library Shared {
    struct Offer {
        uint256 tokenId;
        address erc20Address;
        uint256 amount;
        uint256 createdAt;
        bytes signature;
    }
}