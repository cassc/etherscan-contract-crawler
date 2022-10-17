// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lostkeep + mementos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    –––––––––––––––––––    //
//    lostkeep + mementos    //
//    –––––––––––––––––––    //
//                           //
//                           //
///////////////////////////////


contract LMMTS is ERC721Creator {
    constructor() ERC721Creator("lostkeep + mementos", "LMMTS") {}
}