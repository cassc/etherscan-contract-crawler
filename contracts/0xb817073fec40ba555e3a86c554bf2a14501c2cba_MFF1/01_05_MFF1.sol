// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Final Form 1/1s
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    1MFF = 1MFF    //
//                   //
//                   //
///////////////////////


contract MFF1 is ERC721Creator {
    constructor() ERC721Creator("My Final Form 1/1s", "MFF1") {}
}