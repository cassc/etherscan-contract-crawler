// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Love Tomato Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//                                      //
//     ____   __   ____   __    __      //
//    (  _ \ / _\ (  _ \ /  \  /  \     //
//     ) _ (/    \ ) _ ((  O )(  O )    //
//    (____/\_/\_/(____/ \__/  \__/     //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract BabooNFT is ERC721Creator {
    constructor() ERC721Creator("Love Tomato Art", "BabooNFT") {}
}