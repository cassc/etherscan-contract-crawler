// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: brdg
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//      ___ ____ ___      //
//    //===|====|===\\    //
//                        //
//                        //
////////////////////////////


contract BRDG is ERC721Creator {
    constructor() ERC721Creator("brdg", "BRDG") {}
}