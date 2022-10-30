// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SIS Chan
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    SIS CHAN    //
//                //
//                //
////////////////////


contract SIS is ERC721Creator {
    constructor() ERC721Creator("SIS Chan", "SIS") {}
}