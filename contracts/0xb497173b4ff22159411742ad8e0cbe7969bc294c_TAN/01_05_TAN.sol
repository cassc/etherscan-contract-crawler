// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THOUGHTS ABOUT NFT BY VINPAN
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    ________________    _______       //
//    \__    ___/  _  \   \      \      //
//      |    | /  /_\  \  /   |   \     //
//      |    |/    |    \/    |    \    //
//      |____|\____|__  /\____|__  /    //
//                    \/         \/     //
//                                      //
//                                      //
//////////////////////////////////////////


contract TAN is ERC721Creator {
    constructor() ERC721Creator("THOUGHTS ABOUT NFT BY VINPAN", "TAN") {}
}