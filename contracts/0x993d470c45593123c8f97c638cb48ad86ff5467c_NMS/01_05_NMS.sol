// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NIMS Crypto
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//     _______      _____    _________    //
//     \      \    /     \  /   _____/    //
//     /   |   \  /  \ /  \ \_____  \     //
//    /    |    \/    Y    \/        \    //
//    \____|__  /\____|__  /_______  /    //
//            \/         \/        \/     //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract NMS is ERC721Creator {
    constructor() ERC721Creator("NIMS Crypto", "NMS") {}
}