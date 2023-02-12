// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tagblock
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//     _____            _     _            _        //
//    /__   \__ _  __ _| |__ | | ___   ___| | __    //
//      / /\/ _` |/ _` | '_ \| |/ _ \ / __| |/ /    //
//     / / | (_| | (_| | |_) | | (_) | (__|   <     //
//     \/   \__,_|\__, |_.__/|_|\___/ \___|_|\_\    //
//                |___/                             //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract TAGB is ERC1155Creator {
    constructor() ERC1155Creator("Tagblock", "TAGB") {}
}