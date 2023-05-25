// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Escher Exclusive 4
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    4    //
//         //
//         //
/////////////


contract ESCH4 is ERC1155Creator {
    constructor() ERC1155Creator("Escher Exclusive 4", "ESCH4") {}
}