// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gratitude
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//    |_  _   _  _    _ |. _ _   _ |_  _ |_ _      //
//    |_)| \/| )| )  (_|||_)(-  |_)| )(_)|_(_)     //
//         /                    |                  //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract BAGE is ERC721Creator {
    constructor() ERC721Creator("Gratitude", "BAGE") {}
}