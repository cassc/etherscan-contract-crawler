// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dope
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    Dope    //
//            //
//            //
////////////////


contract Dope is ERC721Creator {
    constructor() ERC721Creator("Dope", "Dope") {}
}