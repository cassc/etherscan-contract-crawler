// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sixtyninecards
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//        __ ___                      _         //
//       / // _ \                    | |        //
//      / /| (_) |   ___ __ _ _ __ __| |___     //
//     | '_ \__, |  / __/ _` | '__/ _` / __|    //
//     | (_) |/ /  | (_| (_| | | | (_| \__ \    //
//      \___//_/    \___\__,_|_|  \__,_|___/    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract SNC is ERC1155Creator {
    constructor() ERC1155Creator("sixtyninecards", "SNC") {}
}