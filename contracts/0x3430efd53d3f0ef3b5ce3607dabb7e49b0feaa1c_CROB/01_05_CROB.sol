// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CuteRobots
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    CuteRobots    //
//                  //
//                  //
//////////////////////


contract CROB is ERC721Creator {
    constructor() ERC721Creator("CuteRobots", "CROB") {}
}