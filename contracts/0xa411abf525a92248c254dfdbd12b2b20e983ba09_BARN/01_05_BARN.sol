// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brynn Alise Photo Editions Winter Barn
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


contract BARN is ERC721Creator {
    constructor() ERC721Creator("Brynn Alise Photo Editions Winter Barn", "BARN") {}
}