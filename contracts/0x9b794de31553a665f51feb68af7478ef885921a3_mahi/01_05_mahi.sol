// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: charcoal
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//                   .__    .__     //
//      _____ _____  |  |__ |__|    //
//     /     \\__  \ |  |  \|  |    //
//    |  Y Y  \/ __ \|   Y  \  |    //
//    |__|_|  (____  /___|  /__|    //
//          \/     \/     \/        //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract mahi is ERC1155Creator {
    constructor() ERC1155Creator("charcoal", "mahi") {}
}