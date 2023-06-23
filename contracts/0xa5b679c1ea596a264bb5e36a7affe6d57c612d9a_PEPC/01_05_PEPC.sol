// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe's Cave
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//       II      //
//       II      //
//      I  I     //
//     I    I    //
//     I    I    //
//     I II I    //
//     I    I    //
//     I    I    //
//     IIIIII    //
//               //
//               //
///////////////////


contract PEPC is ERC721Creator {
    constructor() ERC721Creator("Pepe's Cave", "PEPC") {}
}