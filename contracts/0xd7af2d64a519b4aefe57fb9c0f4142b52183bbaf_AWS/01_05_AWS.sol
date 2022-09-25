// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AWaveStory
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//       _____  __      __ _________    //
//      /  _  \/  \    /  /   _____/    //
//     /  /_\  \   \/\/   \_____  \     //
//    /    |    \        //        \    //
//    \____|__  /\__/\  //_______  /    //
//            \/      \/         \/     //
//                                      //
//                                      //
//////////////////////////////////////////


contract AWS is ERC721Creator {
    constructor() ERC721Creator("AWaveStory", "AWS") {}
}