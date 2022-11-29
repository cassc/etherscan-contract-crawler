// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oncyber Tests
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    ASCI    //
//            //
//            //
////////////////


contract OCT is ERC721Creator {
    constructor() ERC721Creator("Oncyber Tests", "OCT") {}
}