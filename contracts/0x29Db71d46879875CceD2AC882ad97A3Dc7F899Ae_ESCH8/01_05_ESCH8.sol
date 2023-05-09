// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Escher Exclusive 8
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    8    //
//         //
//         //
/////////////


contract ESCH8 is ERC1155Creator {
    constructor() ERC1155Creator("Escher Exclusive 8", "ESCH8") {}
}