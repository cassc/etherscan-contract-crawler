// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: access denied
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    ACCESS DENIED    //
//                     //
//                     //
/////////////////////////


contract XX is ERC721Creator {
    constructor() ERC721Creator("access denied", "XX") {}
}