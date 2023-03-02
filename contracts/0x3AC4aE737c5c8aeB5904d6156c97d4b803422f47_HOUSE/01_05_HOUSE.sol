// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MATE HOUSE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    (*＾▽＾)／    //
//               //
//               //
///////////////////


contract HOUSE is ERC1155Creator {
    constructor() ERC1155Creator("MATE HOUSE", "HOUSE") {}
}