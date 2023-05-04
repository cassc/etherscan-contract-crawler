// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Experimental Series
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


contract BAES is ERC721Creator {
    constructor() ERC721Creator("Experimental Series", "BAES") {}
}