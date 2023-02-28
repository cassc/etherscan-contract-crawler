// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 6MAKER PROTEIN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    (^-^)    //
//             //
//             //
/////////////////


contract MP6 is ERC1155Creator {
    constructor() ERC1155Creator("6MAKER PROTEIN", "MP6") {}
}