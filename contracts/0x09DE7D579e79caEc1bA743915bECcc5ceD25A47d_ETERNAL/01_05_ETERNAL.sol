// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eternally Yours
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Eternally Yours    //
//                       //
//                       //
///////////////////////////


contract ETERNAL is ERC721Creator {
    constructor() ERC721Creator("Eternally Yours", "ETERNAL") {}
}