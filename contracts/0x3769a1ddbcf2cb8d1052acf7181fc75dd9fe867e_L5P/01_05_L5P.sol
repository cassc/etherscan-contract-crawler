// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 5th Partner
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    What?    //
//             //
//             //
/////////////////


contract L5P is ERC721Creator {
    constructor() ERC721Creator("5th Partner", "L5P") {}
}