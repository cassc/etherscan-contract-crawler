// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pashnas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     ____  ____  ____  _     _      ____  ____     //
//    /  __\/  _ \/ ___\/ \ /|/ \  /|/  _ \/ ___\    //
//    |  \/|| / \||    \| |_||| |\ ||| / \||    \    //
//    |  __/| |-||\___ || | ||| | \||| |-||\___ |    //
//    \_/   \_/ \|\____/\_/ \|\_/  \|\_/ \|\____/    //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract pashnas is ERC721Creator {
    constructor() ERC721Creator("pashnas", "pashnas") {}
}