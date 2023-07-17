// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brynn Alise SuperRare
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


contract BASR is ERC721Creator {
    constructor() ERC721Creator("Brynn Alise SuperRare", "BASR") {}
}