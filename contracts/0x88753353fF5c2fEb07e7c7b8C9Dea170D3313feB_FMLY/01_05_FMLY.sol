// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Campfire Bonfire
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//    ________________  .____    _____.___.    //
//    \_   _____/     \ |    |   \__  |   |    //
//     |    __)/  \ /  \|    |    /   |   |    //
//     |     \/    Y    \    |___ \____   |    //
//     \___  /\____|__  /_______ \/ ______|    //
//         \/         \/        \/\/           //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract FMLY is ERC721Creator {
    constructor() ERC721Creator("Campfire Bonfire", "FMLY") {}
}