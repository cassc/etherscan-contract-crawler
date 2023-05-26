// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Escher Exclusive 5
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    5    //
//         //
//         //
/////////////


contract ESCH5 is ERC1155Creator {
    constructor() ERC1155Creator("Escher Exclusive 5", "ESCH5") {}
}