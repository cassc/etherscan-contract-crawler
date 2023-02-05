// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3D BUST MECHA SCULPTURE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    3D BUST MECHA SCULPTURE    //
//                               //
//                               //
///////////////////////////////////


contract VCMECH is ERC1155Creator {
    constructor() ERC1155Creator("3D BUST MECHA SCULPTURE", "VCMECH") {}
}