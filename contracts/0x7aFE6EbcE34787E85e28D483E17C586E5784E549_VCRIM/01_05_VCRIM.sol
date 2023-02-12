// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vizual Criminal
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//     _  _ _ ___  _  _ ____ _      ____ ____ _ _  _ _ __ _ ____ _       //
//      \/  |  /__ |__| |--| |___   |___ |--< | |\/| | | \| |--| |___    //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract VCRIM is ERC721Creator {
    constructor() ERC721Creator("Vizual Criminal", "VCRIM") {}
}