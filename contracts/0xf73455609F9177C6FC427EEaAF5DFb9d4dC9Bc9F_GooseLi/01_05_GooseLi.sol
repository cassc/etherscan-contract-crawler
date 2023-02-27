// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GooseLi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    ///////////////////    //
//    //               //    //
//    //               //    //
//    //    GooseLi    //    //
//    //               //    //
//    //               //    //
//    ///////////////////    //
//                           //
//                           //
///////////////////////////////


contract GooseLi is ERC721Creator {
    constructor() ERC721Creator("GooseLi", "GooseLi") {}
}