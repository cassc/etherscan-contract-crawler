// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bad Girl Riri Checks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    BadGirlRiriChecks    //
//                         //
//                         //
/////////////////////////////


contract Riri is ERC721Creator {
    constructor() ERC721Creator("Bad Girl Riri Checks", "Riri") {}
}