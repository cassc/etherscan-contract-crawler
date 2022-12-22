// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JANK interactive
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    These are my interactive JANKS - Explore and enjoy!    //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract JANKi is ERC721Creator {
    constructor() ERC721Creator("JANK interactive", "JANKi") {}
}