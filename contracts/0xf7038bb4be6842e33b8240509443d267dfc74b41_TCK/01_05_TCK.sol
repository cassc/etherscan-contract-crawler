// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Coldest Key
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Love wins    //
//                 //
//                 //
/////////////////////


contract TCK is ERC721Creator {
    constructor() ERC721Creator("The Coldest Key", "TCK") {}
}