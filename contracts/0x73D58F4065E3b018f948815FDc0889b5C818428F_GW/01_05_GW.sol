// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gods War
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    BEGINS...    //
//                 //
//                 //
/////////////////////


contract GW is ERC721Creator {
    constructor() ERC721Creator("Gods War", "GW") {}
}