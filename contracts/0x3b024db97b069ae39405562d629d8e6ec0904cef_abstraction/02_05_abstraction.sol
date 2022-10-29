// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PURE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    =    //
//         //
//         //
/////////////


contract abstraction is ERC721Creator {
    constructor() ERC721Creator("PURE", "abstraction") {}
}