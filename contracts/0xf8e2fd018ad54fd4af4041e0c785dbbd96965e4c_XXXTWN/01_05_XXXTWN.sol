// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XTown
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     __  __  _____                                 //
//     \ \/ / |_   _|   ___   __      __  _ __       //
//      \  /    | |    / _ \  \ \ /\ / / | '_ \      //
//      /  \    | |   | (_) |  \ V  V /  | | | |     //
//     /_/\_\   |_|    \___/    \_/\_/   |_| |_|.    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract XXXTWN is ERC1155Creator {
    constructor() ERC1155Creator("XTown", "XXXTWN") {}
}