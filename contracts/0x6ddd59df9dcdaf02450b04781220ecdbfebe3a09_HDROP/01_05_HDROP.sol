// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Holiday Drop
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


contract HDROP is ERC721Creator {
    constructor() ERC721Creator("Holiday Drop", "HDROP") {}
}