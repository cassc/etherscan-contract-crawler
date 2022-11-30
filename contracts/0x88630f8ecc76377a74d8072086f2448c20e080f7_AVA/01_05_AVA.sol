// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFT Avatar
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Twitter NFT Avatar    //
//                          //
//                          //
//////////////////////////////


contract AVA is ERC721Creator {
    constructor() ERC721Creator("NFT Avatar", "AVA") {}
}