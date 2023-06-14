// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SCENES
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//       __|   __|  __|   \ |  __|   __|     //
//     \__ \  (     _|   .  |  _|  \__ \     //
//     ____/ \___| ___| _|\_| ___| ____/     //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract SCENES is ERC1155Creator {
    constructor() ERC1155Creator("SCENES", "SCENES") {}
}