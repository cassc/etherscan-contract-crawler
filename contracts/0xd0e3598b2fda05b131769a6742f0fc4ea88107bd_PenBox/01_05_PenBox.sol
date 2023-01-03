// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pen Box Studio Delights
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//     __      //
//    (__)     //
//    |  |\    //
//    |  ||    //
//    |  ||    //
//    |__||    //
//    |  |     //
//    |  |     //
//    |  |     //
//    |  |     //
//    |__|     //
//    \||/     //
//     \/      //
//             //
//             //
/////////////////


contract PenBox is ERC721Creator {
    constructor() ERC721Creator("Pen Box Studio Delights", "PenBox") {}
}