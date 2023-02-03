// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trik
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//                  //
//     +-+-+-+-+    //
//     |T|r|i|k|    //
//     +-+-+-+-+    //
//                  //
//                  //
//                  //
//////////////////////


contract Trik is ERC721Creator {
    constructor() ERC721Creator("Trik", "Trik") {}
}