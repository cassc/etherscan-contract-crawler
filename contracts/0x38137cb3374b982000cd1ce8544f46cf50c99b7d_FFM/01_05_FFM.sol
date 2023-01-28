// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FirstFM
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    ________________       //
//    \_   _____/     \      //
//     |    __)/  \ /  \     //
//     |     \/    Y    \    //
//     \___  /\____|__  /    //
//         \/         \/     //
//                           //
//                           //
///////////////////////////////


contract FFM is ERC1155Creator {
    constructor() ERC1155Creator("FirstFM", "FFM") {}
}