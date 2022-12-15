// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tonakai editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//                           //
//      _____ _   _ _  __    //
//     |_   _| \ | | |/ /    //
//       | | |  \| | ' /     //
//       | | | |\  | . \     //
//       |_| |_| \_|_|\_\    //
//                           //
//                           //
//                           //
//                           //
//                           //
///////////////////////////////


contract TNK is ERC1155Creator {
    constructor() ERC1155Creator("Tonakai editions", "TNK") {}
}