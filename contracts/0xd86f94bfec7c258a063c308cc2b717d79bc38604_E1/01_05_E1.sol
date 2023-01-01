// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ediep 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//            E          //
//            D          //
//            I          //
//            E          //
//    E D I E P          //
//              1        //
//                /      //
//                  1    //
//                       //
//                       //
///////////////////////////


contract E1 is ERC721Creator {
    constructor() ERC721Creator("ediep 1/1s", "E1") {}
}