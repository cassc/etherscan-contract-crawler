// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hero Armoury
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Shy Hero    //
//                //
//                //
////////////////////


contract SHYHA is ERC721Creator {
    constructor() ERC721Creator("Hero Armoury", "SHYHA") {}
}