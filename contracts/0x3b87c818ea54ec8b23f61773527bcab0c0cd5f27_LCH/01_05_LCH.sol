// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Other Side
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    _    _  _ ____ _  _ ____ _  _ ____     //
//    |    |  | |    |__| |  | |\ | | __     //
//    |___ |__| |___ |  | |__| | \| |__]     //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract LCH is ERC721Creator {
    constructor() ERC721Creator("The Other Side", "LCH") {}
}