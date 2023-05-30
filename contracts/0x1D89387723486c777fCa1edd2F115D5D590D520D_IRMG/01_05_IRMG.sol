// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IROIRO × MEGAMI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    （っ ‘ ᵕ ‘ ｃ）    //
//                   //
//                   //
///////////////////////


contract IRMG is ERC1155Creator {
    constructor() ERC1155Creator(unicode"IROIRO × MEGAMI", "IRMG") {}
}