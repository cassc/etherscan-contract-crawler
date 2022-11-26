// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unscripted
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    /// Unscripted by nieldlr ///    //
//                                     //
//                                     //
/////////////////////////////////////////


contract UNSCR is ERC721Creator {
    constructor() ERC721Creator("Unscripted", "UNSCR") {}
}