// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test109
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    TESTING!    //
//                //
//                //
////////////////////


contract T35T is ERC721Creator {
    constructor() ERC721Creator("test109", "T35T") {}
}