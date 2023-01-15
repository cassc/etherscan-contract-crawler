// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ogura
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    (*^_^*)ｖ(*^_^*)     //
//                        //
//                        //
////////////////////////////


contract OGURA is ERC721Creator {
    constructor() ERC721Creator("Ogura", "OGURA") {}
}