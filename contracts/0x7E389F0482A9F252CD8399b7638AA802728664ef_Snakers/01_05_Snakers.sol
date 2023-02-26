// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Snakers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    First interactive snake HTML NFT                         //
//    The more you score - the more you will be rewarded...    //
//                                                             //
//    twitter: https://twitter.com/snakers_nft                 //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract Snakers is ERC721Creator {
    constructor() ERC721Creator("Snakers", "Snakers") {}
}