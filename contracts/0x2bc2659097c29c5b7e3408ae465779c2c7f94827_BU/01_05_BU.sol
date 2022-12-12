// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anna Bu
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//        ___                           ____           //
//       /   |  ____  ____  ____ _     / __ )__  __    //
//      / /| | / __ \/ __ \/ __ `/    / __  / / / /    //
//     / ___ |/ / / / / / / /_/ /    / /_/ / /_/ /     //
//    /_/  |_/_/ /_/_/ /_/\__,_/    /_____/\__,_/      //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract BU is ERC1155Creator {
    constructor() ERC1155Creator("Anna Bu", "BU") {}
}