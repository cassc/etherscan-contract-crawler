// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Second Supply
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    ⣾⡟⠀⢰⡿⠁⢠⣿⡏⠁⣰⣾⠟⠉⠉⠉⠛⣿⣶⠈⢻⣷⡀⠈     //
//    ⣿⡇⠀⣿⡇⠀⣿⣿⠀⢸⣿ 🐸 ⡇⢰⣿⢸⣿⠀⢸⣿⡇⠀    //
//    ⣾⡟⠀⢰⡿⠁⢠⣿⡏⠁⣰⣾⠟⠉⠉⠉⠛⣿⣶⠈⢻⣷⡀⠈     //
//                                 //
//                                 //
/////////////////////////////////////


contract THRIFT is ERC1155Creator {
    constructor() ERC1155Creator("Second Supply", "THRIFT") {}
}