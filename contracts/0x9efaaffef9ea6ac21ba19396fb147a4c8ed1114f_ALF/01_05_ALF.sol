// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ɅLFIE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    uncultured pixels & degenerate bits    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract ALF is ERC721Creator {
    constructor() ERC721Creator(unicode"ɅLFIE", "ALF") {}
}