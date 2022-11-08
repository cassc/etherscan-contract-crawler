// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GoTo0
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//     _____     _____     ___     //
//    |   __|___|_   _|___|   |    //
//    |  |  | . | | | | . | | |    //
//    |_____|___| |_| |___|___|    //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract GT0 is ERC721Creator {
    constructor() ERC721Creator("GoTo0", "GT0") {}
}