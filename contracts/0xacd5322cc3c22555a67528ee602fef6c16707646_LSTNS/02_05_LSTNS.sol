// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lostkeep + stations
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    –––––––––––––––––––    //
//    lostkeep + stations    //
//    –––––––––––––––––––    //
//                           //
//                           //
///////////////////////////////


contract LSTNS is ERC721Creator {
    constructor() ERC721Creator("lostkeep + stations", "LSTNS") {}
}