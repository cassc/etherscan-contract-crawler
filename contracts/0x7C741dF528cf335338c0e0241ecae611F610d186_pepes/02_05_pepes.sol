// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ordinal Pepes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    pepe love you    //
//                     //
//                     //
/////////////////////////


contract pepes is ERC721Creator {
    constructor() ERC721Creator("ordinal Pepes", "pepes") {}
}