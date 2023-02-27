// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Frank America Ephemera
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    A collection of ephemera by Frank America.    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract FRNKMRK is ERC1155Creator {
    constructor() ERC1155Creator("Frank America Ephemera", "FRNKMRK") {}
}