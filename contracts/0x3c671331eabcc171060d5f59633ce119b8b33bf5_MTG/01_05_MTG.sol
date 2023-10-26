// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Deployment
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//       ________________________     //
//      /     \__    ___/  _____/     //
//     /  \ /  \|    | /   \  ___     //
//    /    Y    \    | \    \_\  \    //
//    \____|__  /____|  \______  /    //
//            \/               \/     //
//                                    //
//                                    //
////////////////////////////////////////


contract MTG is ERC721Creator {
    constructor() ERC721Creator("Deployment", "MTG") {}
}