// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Escher Exclusive 7
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    7    //
//         //
//         //
/////////////


contract ESCH7 is ERC1155Creator {
    constructor() ERC1155Creator("Escher Exclusive 7", "ESCH7") {}
}