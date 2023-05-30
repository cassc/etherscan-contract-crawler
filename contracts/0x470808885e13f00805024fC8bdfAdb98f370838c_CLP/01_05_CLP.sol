// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cleithrophobia
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    No ASCII Art here \(•◡•)/                     //
//                                                  //
//    Cleithrophobia                                //
//    by David Loh                                  //
//                                                  //
//    Recurring dreams of being trapped indoors.    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract CLP is ERC721Creator {
    constructor() ERC721Creator("Cleithrophobia", "CLP") {}
}