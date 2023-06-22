// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Joker 12
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//         _       _               __ ___       //
//         | |     | |             /_ |__ \     //
//         | | ___ | | _____ _ __   | |  ) |    //
//     _   | |/ _ \| |/ / _ \ '__|  | | / /     //
//    | |__| | (_) |   <  __/ |     | |/ /_     //
//     \____/ \___/|_|\_\___|_|     |_|____|    //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract J12 is ERC1155Creator {
    constructor() ERC1155Creator("Joker 12", "J12") {}
}