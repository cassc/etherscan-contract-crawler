// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sam Spratt - The Key to The Monument Game
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    Congratulations. Transfer and Hold. Keep it safe.    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract LUCI is ERC721Creator {
    constructor() ERC721Creator("Sam Spratt - The Key to The Monument Game", "LUCI") {}
}