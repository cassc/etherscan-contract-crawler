// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: particles
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    ._  _  _._    |      //
//    | |(_)(_| \/\/|      //
//                         //
//                         //
/////////////////////////////


contract prtcls is ERC721Creator {
    constructor() ERC721Creator("particles", "prtcls") {}
}