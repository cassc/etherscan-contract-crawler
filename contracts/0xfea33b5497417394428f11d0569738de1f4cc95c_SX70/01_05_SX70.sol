// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Polaroid
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    [ o°]    //
//             //
//             //
/////////////////


contract SX70 is ERC1155Creator {
    constructor() ERC1155Creator("Polaroid", "SX70") {}
}