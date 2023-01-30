// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Journey
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    My journey around the world.    //
//                                    //
//                                    //
////////////////////////////////////////


contract MJ is ERC1155Creator {
    constructor() ERC1155Creator("My Journey", "MJ") {}
}