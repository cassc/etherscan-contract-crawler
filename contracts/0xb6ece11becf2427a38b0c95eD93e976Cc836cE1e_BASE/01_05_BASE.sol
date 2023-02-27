// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BASEwanted
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//     ____   __   ____  ____     //
//    (  _ \ / _\ / ___)(  __)    //
//     ) _ (/    \\___ \ ) _)     //
//    (____/\_/\_/(____/(____)    //
//                                //
//                                //
////////////////////////////////////


contract BASE is ERC721Creator {
    constructor() ERC721Creator("BASEwanted", "BASE") {}
}