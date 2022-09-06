// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glass Orchids
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     +-+-+-+-+-+ +-+-+-+-+-+-+-+    //
//     |G|l|a|s|s| |O|r|c|h|i|d|s|    //
//     +-+-+-+-+-+ +-+-+-+-+-+-+-+    //
//                                    //
//                                    //
////////////////////////////////////////


contract ORCH is ERC721Creator {
    constructor() ERC721Creator("Glass Orchids", "ORCH") {}
}