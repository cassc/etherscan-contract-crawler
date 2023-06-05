// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ESCA Benefits
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    ＊＊＊＊＊＊    //
//              //
//              //
//////////////////


contract ESCABene is ERC1155Creator {
    constructor() ERC1155Creator("ESCA Benefits", "ESCABene") {}
}