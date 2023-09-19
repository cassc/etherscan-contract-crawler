// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ndhoz_Dotule
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//                                     //
//      _   _     _ _                  //
//     | \ | |   | | |                 //
//     |  \| | __| | |__   ___ ____    //
//     | . ` |/ _` | '_ \ / _ \_  /    //
//     | |\  | (_| | | | | (_) / /     //
//     |_| \_|\__,_|_| |_|\___/___|    //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract NDHOZ is ERC1155Creator {
    constructor() ERC1155Creator("Ndhoz_Dotule", "NDHOZ") {}
}