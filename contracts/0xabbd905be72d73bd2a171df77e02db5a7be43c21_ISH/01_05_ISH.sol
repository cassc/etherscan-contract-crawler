// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ishleen Kaur Art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//      _____  _____ _    _     //
//     |_   _|/ ____| |  | |    //
//       | | | (___ | |__| |    //
//       | |  \___ \|  __  |    //
//      _| |_ ____) | |  | |    //
//     |_____|_____/|_|  |_|    //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract ISH is ERC1155Creator {
    constructor() ERC1155Creator("Ishleen Kaur Art", "ISH") {}
}