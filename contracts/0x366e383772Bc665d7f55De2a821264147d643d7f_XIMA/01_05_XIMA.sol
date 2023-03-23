// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Xima's Underwolrd
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//    \  \/// \/ \__/|/  _ \    //
//     \  / | || |\/||| / \|    //
//     /  \ | || |  ||| |-||    //
//    /__/\\\_/\_/  \|\_/ \|    //
//                              //
//                              //
//                              //
//////////////////////////////////


contract XIMA is ERC721Creator {
    constructor() ERC721Creator("Xima's Underwolrd", "XIMA") {}
}