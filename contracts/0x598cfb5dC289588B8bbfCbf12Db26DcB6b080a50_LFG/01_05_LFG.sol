// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Emmy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//     _        ______  ______      //
//    | |      | |     | | ____     //
//    | |   _  | |---- | |  | |     //
//    |_|__|_| |_|     |_|__|_|     //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract LFG is ERC1155Creator {
    constructor() ERC1155Creator("Emmy", "LFG") {}
}