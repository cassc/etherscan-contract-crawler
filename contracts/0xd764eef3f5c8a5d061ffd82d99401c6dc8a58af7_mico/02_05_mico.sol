// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: asra_khani
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//                                      //
//    _____    __________________       //
//    \__  \  /  ___/\_  __ \__  \      //
//     / __ \_\___ \  |  | \// __ \_    //
//    (____  /____  > |__|  (____  /    //
//         \/     \/             \/     //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract mico is ERC721Creator {
    constructor() ERC721Creator("asra_khani", "mico") {}
}