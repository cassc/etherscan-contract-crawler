// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: This Time Around
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Jake Inez    //
//                 //
//                 //
/////////////////////


contract JAKE is ERC721Creator {
    constructor() ERC721Creator("This Time Around", "JAKE") {}
}