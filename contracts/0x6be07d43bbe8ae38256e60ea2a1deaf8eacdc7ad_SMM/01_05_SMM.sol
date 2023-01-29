// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: System of memes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    Cos4mos72    //
//                 //
//                 //
/////////////////////


contract SMM is ERC1155Creator {
    constructor() ERC1155Creator("System of memes", "SMM") {}
}