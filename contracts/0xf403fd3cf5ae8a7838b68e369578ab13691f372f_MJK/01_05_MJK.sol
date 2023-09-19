// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SERDAR MJK
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    Serdar Mjk Tepe - Open Editions    //
//                                       //
//                                       //
///////////////////////////////////////////


contract MJK is ERC721Creator {
    constructor() ERC721Creator("SERDAR MJK", "MJK") {}
}