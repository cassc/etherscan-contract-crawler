// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PePe SB Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    IIIIIIIIII        //
//    I  I  I. I        //
//    I  I  I. I        //
//    I  I  I. I        //
//    I  I  I  I        //
//    IIIIIIIIII        //
//    I.       I        //
//    I        I        //
//    I        I        //
//    I        I        //
//    I.       I SB.    //
//                      //
//                      //
//////////////////////////


contract EDPP is ERC721Creator {
    constructor() ERC721Creator("PePe SB Editions", "EDPP") {}
}