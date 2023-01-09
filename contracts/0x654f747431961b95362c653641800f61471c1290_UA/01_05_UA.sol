// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Underwater Abyss
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//    Underwater Abyss will serve as the Genesis collection, and as a Key for future access to all future collections released.    //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UA is ERC721Creator {
    constructor() ERC721Creator("Underwater Abyss", "UA") {}
}