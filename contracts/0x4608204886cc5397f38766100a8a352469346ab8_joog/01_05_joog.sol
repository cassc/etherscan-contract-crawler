// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: joogasama
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//        ______  ________  ________  ________     //
//       ╱      ╲╱        ╲╱        ╲╱        ╲    //
//      ╱       ╱         ╱         ╱       __╱    //
//    _╱       ╱         ╱         ╱       ╱ ╱     //
//    ╲_______╱╲________╱╲________╱╲________╱      //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract joog is ERC721Creator {
    constructor() ERC721Creator("joogasama", "joog") {}
}