// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Escher Exclusive 6
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    6    //
//         //
//         //
/////////////


contract ESCH6 is ERC1155Creator {
    constructor() ERC1155Creator("Escher Exclusive 6", "ESCH6") {}
}