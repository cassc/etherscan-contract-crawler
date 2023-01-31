// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HaSan
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//      ___ ___          _________                  //
//     /   |   \_____   /   _____/____    ____      //
//    /    ~    \__  \  \_____  \\__  \  /    \     //
//    \    Y    // __ \_/        \/ __ \|   |  \    //
//     \___|_  /(____  /_______  (____  /___|  /    //
//           \/      \/        \/     \/     \/     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract MGCL8 is ERC721Creator {
    constructor() ERC721Creator("HaSan", "MGCL8") {}
}