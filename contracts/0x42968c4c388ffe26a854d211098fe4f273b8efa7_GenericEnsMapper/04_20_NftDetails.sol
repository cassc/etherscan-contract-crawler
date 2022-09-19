// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

struct NftDetails {
    uint256 ParentTokenId;
    string Label;
    IERC721 NftAddress;
    uint96 NftId; //this actually saves about 20,000 gas in the claim subdomain method
}