// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MGNia
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//      __  __  ____ _   _ _           //
//     |  \/  |/ ___| \ | (_) __ _     //
//     | |\/| | |  _|  \| | |/ _` |    //
//     | |  | | |_| | |\  | | (_| |    //
//     |_|  |_|\____|_| \_|_|\__,_|    //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract MGNia is ERC1155Creator {
    constructor() ERC1155Creator("MGNia", "MGNia") {}
}