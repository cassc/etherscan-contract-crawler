// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art in the Machine II
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//      ___________________     //
//     /  _____/\__    ___/     //
//    /   \  ___  |    |        //
//    \    \_\  \ |    |        //
//     \______  / |____|        //
//            \/                //
//                              //
//                              //
//                              //
//////////////////////////////////


contract AIMII is ERC721Creator {
    constructor() ERC721Creator("Art in the Machine II", "AIMII") {}
}