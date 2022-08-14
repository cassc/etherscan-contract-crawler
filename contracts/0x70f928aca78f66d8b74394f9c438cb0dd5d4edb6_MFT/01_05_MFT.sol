// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MFTest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    xxxxx    //
//             //
//             //
/////////////////


contract MFT is ERC721Creator {
    constructor() ERC721Creator("MFTest", "MFT") {}
}