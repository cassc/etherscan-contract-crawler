// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract TWEdtns is ERC721Creator {
    constructor() ERC721Creator("Editions", "TWEdtns") {}
}