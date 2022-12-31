// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YUCAI Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//     __     __  _    _      _____              _____     //
//     \ \   / / | |  | |    / ____|     /\     |_   _|    //
//      \ \_/ /  | |  | |   | |         /  \      | |      //
//       \   /   | |  | |   | |        / /\ \     | |      //
//        | |    | |__| |   | |____   / ____ \   _| |_     //
//        |_|     \____/     \_____| /_/    \_\ |_____|    //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract YUCAI is ERC1155Creator {
    constructor() ERC1155Creator("YUCAI Editions", "YUCAI") {}
}