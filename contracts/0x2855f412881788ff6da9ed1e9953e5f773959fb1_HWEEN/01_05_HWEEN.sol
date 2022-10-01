// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: This is Hailloween
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    HWEEN    //
//             //
//             //
/////////////////


contract HWEEN is ERC721Creator {
    constructor() ERC721Creator("This is Hailloween", "HWEEN") {}
}