// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CC-0E
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//       ____________   ____  ______    //
//      / ____/ ____/  / __ \/ ____/    //
//     / /   / /      / / / / __/       //
//    / /___/ /___   / /_/ / /___       //
//    \____/\____/   \____/_____/       //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract CCOE is ERC1155Creator {
    constructor() ERC1155Creator("CC-0E", "CCOE") {}
}