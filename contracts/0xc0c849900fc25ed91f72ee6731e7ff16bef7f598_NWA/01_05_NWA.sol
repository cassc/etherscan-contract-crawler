// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Network Artifacts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    (0.o) <3    //
//                //
//                //
////////////////////


contract NWA is ERC721Creator {
    constructor() ERC721Creator("Network Artifacts", "NWA") {}
}