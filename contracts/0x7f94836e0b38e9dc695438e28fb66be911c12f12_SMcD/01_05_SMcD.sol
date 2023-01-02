// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ShonaMcD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    SMcD    //
//            //
//            //
////////////////


contract SMcD is ERC721Creator {
    constructor() ERC721Creator("ShonaMcD", "SMcD") {}
}