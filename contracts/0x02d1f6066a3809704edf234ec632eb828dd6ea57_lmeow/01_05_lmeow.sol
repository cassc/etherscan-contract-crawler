// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lmeow
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//      _                                  //
//     | |_ __ ___   ___  _____      __    //
//     | | '_ ` _ \ / _ \/ _ \ \ /\ / /    //
//     | | | | | | |  __/ (_) \ V  V /     //
//     |_|_| |_| |_|\___|\___/ \_/\_/      //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract lmeow is ERC1155Creator {
    constructor() ERC1155Creator("lmeow", "lmeow") {}
}