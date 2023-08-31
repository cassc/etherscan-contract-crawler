// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Monument Game Factory
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    …    //
//         //
//         //
/////////////


contract TMGF is ERC1155Creator {
    constructor() ERC1155Creator("The Monument Game Factory", "TMGF") {}
}