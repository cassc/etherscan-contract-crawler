// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: w0rlds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//     _  _   __  ____  __    ____  ____           //
//    / )( \ /  \(  _ \(  )  (    \/ ___)          //
//    \ /\ /(  0 ))   // (_/\ ) D (\___ \          //
//    (_/\_) \__/(__\_)\____/(____/(____/          //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract WRLDS is ERC721Creator {
    constructor() ERC721Creator("w0rlds", "WRLDS") {}
}