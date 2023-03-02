// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ParentApeGeneLab
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                           //
//                                                                                                                                                                           //
//    This collection of grandmothers of legendary monkeys. Stay with us, soon we will be joined by grandfathers, steak, and joining the legendary collection of monkeys.    //
//                                                                                                                                                                           //
//                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PAGL is ERC721Creator {
    constructor() ERC721Creator("ParentApeGeneLab", "PAGL") {}
}