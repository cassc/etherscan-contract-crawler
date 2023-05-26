// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Collin's Cryptoart & Trashart
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    COLLIN'S CRYPTOART & TRASHART     //
//     ___/-\___                        //
//    |---------|                       //
//     | | | | |                        //
//     | | | | |                        //
//     | | | | |                        //
//     | | | | |                        //
//     |_______|                        //
//                                      //
//                                      //
//////////////////////////////////////////


contract collin is ERC721Creator {
    constructor() ERC721Creator("Collin's Cryptoart & Trashart", "collin") {}
}