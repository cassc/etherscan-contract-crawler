// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: One Town Over
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
//    You know, my words have been a shield for all my life    //
//    I sang a swan, it gave me wings to fly                   //
//    And in the absence of an echo, ego dies                  //
//    And in the absence of myself I came to find              //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract OVERTHEHILLS is ERC1155Creator {
    constructor() ERC1155Creator("One Town Over", "OVERTHEHILLS") {}
}