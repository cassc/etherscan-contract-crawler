// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ada Ossica
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Ada Ossica     //
//                   //
//                   //
///////////////////////


contract AdaO is ERC721Creator {
    constructor() ERC721Creator("Ada Ossica", "AdaO") {}
}