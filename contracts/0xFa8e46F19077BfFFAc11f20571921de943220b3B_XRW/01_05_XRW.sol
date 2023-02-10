// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: X - RW Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    __  __                            //
//    \ \/ /                            //
//     >  <  - realize worthlessness    //
//    /_/\_\                            //
//                                      //
//                                      //
//////////////////////////////////////////


contract XRW is ERC721Creator {
    constructor() ERC721Creator("X - RW Edition", "XRW") {}
}