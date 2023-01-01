// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Justin Maller
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    p  l  a  c  e  h  o  l  d  e  r    //
//                                       //
//                                       //
///////////////////////////////////////////


contract JMM is ERC721Creator {
    constructor() ERC721Creator("Justin Maller", "JMM") {}
}