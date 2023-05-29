// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HOODLABORATORY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    10001    //
//             //
//             //
/////////////////


contract LAB is ERC721Creator {
    constructor() ERC721Creator("HOODLABORATORY", "LAB") {}
}