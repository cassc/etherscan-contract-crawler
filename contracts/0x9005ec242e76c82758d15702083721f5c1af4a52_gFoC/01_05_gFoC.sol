// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mathias Kniepeiss
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//                                         //
//           ___________    _________      //
//       ____\_   _____/___ \_   ___ \     //
//      / ___\|    __)/  _ \/    \  \/     //
//     / /_/  >     \(  <_> )     \____    //
//     \___  /\___  / \____/ \______  /    //
//    /_____/     \/                \/     //
//                                         //
//                                         //
/////////////////////////////////////////////


contract gFoC is ERC721Creator {
    constructor() ERC721Creator("Mathias Kniepeiss", "gFoC") {}
}