// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chex - by Bird
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//       ____               ____     ____        //
//    U | __")u    ___   U |  _"\ u |  _"\       //
//     \|  _ \/   |_"_|   \| |_) |//| | | |      //
//      | |_) |    | |     |  _ <  U| |_| |\     //
//      |____/   U/| |\u   |_| \_\  |____/ u     //
//     _|| \\_.-,_|___|_,-.//   \\_  |||_        //
//    (__) (__)\_)-' '-(_/(__)  (__)(__)_)       //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract CHEX is ERC1155Creator {
    constructor() ERC1155Creator("Chex - by Bird", "CHEX") {}
}