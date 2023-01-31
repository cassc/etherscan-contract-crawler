// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Book Of Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//                          //
//     ____  ____  ____     //
//    /  __\/  _ \/  _ \    //
//    | | //| / \|| / \|    //
//    | |_\\| \_/|| |-||    //
//    \____/\____/\_/ \|    //
//                          //
//                          //
//                          //
//                          //
//////////////////////////////


contract BOA is ERC721Creator {
    constructor() ERC721Creator("The Book Of Art", "BOA") {}
}