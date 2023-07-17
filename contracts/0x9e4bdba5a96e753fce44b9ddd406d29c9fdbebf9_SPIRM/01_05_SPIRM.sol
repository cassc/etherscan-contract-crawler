// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spiritual Messenger
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//    D)dddd                                       //
//    D)   dd                                      //
//    D)    dd a)AAAA  a)AAAA  n)NNNN   s)SSSS     //
//    D)    dd  a)AAA   a)AAA  n)   NN s)SSSS      //
//    D)    dd a)   A  a)   A  n)   NN      s)     //
//    D)ddddd   a)AAAA  a)AAAA n)   NN s)SSSS      //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract SPIRM is ERC721Creator {
    constructor() ERC721Creator("Spiritual Messenger", "SPIRM") {}
}