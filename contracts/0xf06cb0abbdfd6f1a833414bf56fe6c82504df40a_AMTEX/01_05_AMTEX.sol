// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DIGITAL CALLIGRAPHY DOLL AMATSU EX
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    ////////////////////     //
//    //                //     //
//    //    AMATSU EX   //     //
//    //                //     //
//    ////////////////////     //
//                             //
//                             //
/////////////////////////////////


contract AMTEX is ERC721Creator {
    constructor() ERC721Creator("DIGITAL CALLIGRAPHY DOLL AMATSU EX", "AMTEX") {}
}