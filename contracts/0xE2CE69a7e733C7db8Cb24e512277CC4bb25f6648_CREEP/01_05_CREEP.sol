// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Creeper 1/1's
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//         _____       //
//       /       \     //
//      |  x   x  |    //
//      |    ^    |    //
//      |  \___/  |    //
//       \_______/     //
//                     //
//                     //
//                     //
/////////////////////////


contract CREEP is ERC721Creator {
    constructor() ERC721Creator("Creeper 1/1's", "CREEP") {}
}