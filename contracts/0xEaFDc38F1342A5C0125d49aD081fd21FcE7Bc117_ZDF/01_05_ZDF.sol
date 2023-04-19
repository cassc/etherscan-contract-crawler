// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZEDDIFY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    ///////////////////    //
//    //               //    //
//    //               //    //
//    //    ZEDDIFY    //    //
//    //               //    //
//    //               //    //
//    ///////////////////    //
//                           //
//                           //
//                           //
///////////////////////////////


contract ZDF is ERC721Creator {
    constructor() ERC721Creator("ZEDDIFY", "ZDF") {}
}