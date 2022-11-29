// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Singles
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Testing...    //
//                  //
//                  //
//////////////////////


contract TST is ERC721Creator {
    constructor() ERC721Creator("Test Singles", "TST") {}
}