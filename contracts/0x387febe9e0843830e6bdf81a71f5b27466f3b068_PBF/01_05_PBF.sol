// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Out of the Blue
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//     +-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+    //
//     |P|h|o|t|o|s| |b|y| |F|r|a|n|k|    //
//     +-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+    //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract PBF is ERC1155Creator {
    constructor() ERC1155Creator("Out of the Blue", "PBF") {}
}