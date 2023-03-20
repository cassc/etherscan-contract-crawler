// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE IS LOVE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//    __________________________________________    //
//    \______   \_   _____/\______   \_   _____/    //
//     |     ___/|    __)_  |     ___/|    __)_     //
//     |    |    |        \ |    |    |        \    //
//     |____|   /_______  / |____|   /_______  /    //
//                      \/                   \/     //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract PEPE is ERC721Creator {
    constructor() ERC721Creator("PEPE IS LOVE", "PEPE") {}
}