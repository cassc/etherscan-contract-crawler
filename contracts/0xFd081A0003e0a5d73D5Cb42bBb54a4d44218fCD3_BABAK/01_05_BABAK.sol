// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Babaka
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    ///////////////////    //
//    //               //    //
//    //               //    //
//    //    babakas    //    //
//    //               //    //
//    //               //    //
//    ///////////////////    //
//                           //
//                           //
///////////////////////////////


contract BABAK is ERC721Creator {
    constructor() ERC721Creator("Babaka", "BABAK") {}
}