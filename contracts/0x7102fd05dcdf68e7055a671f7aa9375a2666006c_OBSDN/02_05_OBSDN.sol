// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Obsisian
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//           _          _     _ _                 //
//          | |        (_)   | (_)                //
//      ___ | |__   ___ _  __| |_ _____ ____      //
//     / _ \|  _ \ /___| |/ _  | (____ |  _ \     //
//    | |_| | |_) |___ | ( (_| | / ___ | | | |    //
//     \___/|____/(___/|_|\____|_\_____|_| |_|    //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract OBSDN is ERC721Creator {
    constructor() ERC721Creator("Obsisian", "OBSDN") {}
}