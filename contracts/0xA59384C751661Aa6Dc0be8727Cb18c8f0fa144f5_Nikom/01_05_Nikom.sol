// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Diary illustration
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    Nikom    //
//             //
//             //
/////////////////


contract Nikom is ERC721Creator {
    constructor() ERC721Creator("Diary illustration", "Nikom") {}
}