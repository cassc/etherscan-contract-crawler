// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Light Breathing
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//     +-+-+-+-+-+-+-+ +-+-+-+-+    //
//     |K|a|t|r|i|n|a| |R|i|r|i|    //
//     +-+-+-+-+-+-+-+ +-+-+-+-+    //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract LightBreathing is ERC721Creator {
    constructor() ERC721Creator("Light Breathing", "LightBreathing") {}
}