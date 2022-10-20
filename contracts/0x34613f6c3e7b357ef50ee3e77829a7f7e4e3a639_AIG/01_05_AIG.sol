// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Adventures in Gratitude
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//    Hey, thanks for doing that thing you did. You're great!    //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract AIG is ERC721Creator {
    constructor() ERC721Creator("Adventures in Gratitude", "AIG") {}
}