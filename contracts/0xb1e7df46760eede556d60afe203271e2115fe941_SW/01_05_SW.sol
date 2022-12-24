// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: StrongWeird
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//                     //
//    __   ___   _     //
//    \ \ / / | | |    //
//     \ V /| | | |    //
//      \ / | | | |    //
//      | | | |_| |    //
//      \_/  \___/     //
//                     //
//                     //
//                     //
//                     //
//                     //
/////////////////////////


contract SW is ERC1155Creator {
    constructor() ERC1155Creator("StrongWeird", "SW") {}
}