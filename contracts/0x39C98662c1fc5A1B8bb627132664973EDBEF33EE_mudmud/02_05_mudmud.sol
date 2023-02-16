// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MudMud
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                      .___    //
//      _____  __ __  __| _/    //
//     /     \|  |  \/ __ |     //
//    |  Y Y  \  |  / /_/ |     //
//    |__|_|  /____/\____ |     //
//          \/           \/     //
//                              //
//                              //
//////////////////////////////////


contract mudmud is ERC1155Creator {
    constructor() ERC1155Creator("MudMud", "mudmud") {}
}