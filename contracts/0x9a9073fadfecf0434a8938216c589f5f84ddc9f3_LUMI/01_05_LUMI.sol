// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lumière
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//     +-+-+-+-+    //
//     |L|U|M|I|    //
//     +-+-+-+-+    //
//                  //
//                  //
//////////////////////


contract LUMI is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Lumière", "LUMI") {}
}