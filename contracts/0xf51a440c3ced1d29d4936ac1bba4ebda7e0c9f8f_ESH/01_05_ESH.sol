// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: space hunters
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                         //
//                                                                                                                                                                         //
//    Space hunters-hunters for space resources. A metaverse where you can travel with your friends to other worlds and extract resources for your colony.                 //
//    Space hunters gives owners access to a beta test in the universe of The Space Craftsman, which means you can bite off your piece of the universe before the rest!    //
//                                                                                                                                                                         //
//                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ESH is ERC1155Creator {
    constructor() ERC1155Creator("space hunters", "ESH") {}
}