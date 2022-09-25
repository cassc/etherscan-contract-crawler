// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Loading
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//       _____      _____ _____.___._________      //
//      /     \    /  _  \\__  |   |\_   ___ \     //
//     /  \ /  \  /  /_\  \/   |   |/    \  \/     //
//    /    Y    \/    |    \____   |\     \____    //
//    \____|__  /\____|__  / ______| \______  /    //
//            \/         \/\/               \/     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract MAYC is ERC721Creator {
    constructor() ERC721Creator("Loading", "MAYC") {}
}