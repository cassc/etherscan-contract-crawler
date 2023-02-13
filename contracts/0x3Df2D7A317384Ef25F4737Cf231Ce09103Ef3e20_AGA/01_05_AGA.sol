// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Agatha Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//        ___   _________  ________  _____     //
//       /   | / ____/   |/_  __/ / / /   |    //
//      / /| |/ / __/ /| | / / / /_/ / /| |    //
//     / ___ / /_/ / ___ |/ / / __  / ___ |    //
//    /_/  |_\____/_/  |_/_/ /_/ /_/_/  |_|    //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract AGA is ERC721Creator {
    constructor() ERC721Creator("Agatha Art", "AGA") {}
}