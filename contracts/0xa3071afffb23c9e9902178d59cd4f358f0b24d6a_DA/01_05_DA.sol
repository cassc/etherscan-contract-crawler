// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Digital Academy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//    ________      _____       //
//    \______ \    /  _  \      //
//     |    |  \  /  /_\  \     //
//     |    `   \/    |    \    //
//    /_______  /\____|__  /    //
//            \/         \/     //
//                              //
//                              //
//                              //
//////////////////////////////////


contract DA is ERC721Creator {
    constructor() ERC721Creator("Digital Academy", "DA") {}
}