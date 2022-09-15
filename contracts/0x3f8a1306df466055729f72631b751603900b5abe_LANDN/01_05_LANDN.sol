// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Contract
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    This is my ASCII mark and I'm proud of it.     //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract LANDN is ERC721Creator {
    constructor() ERC721Creator("Test Contract", "LANDN") {}
}