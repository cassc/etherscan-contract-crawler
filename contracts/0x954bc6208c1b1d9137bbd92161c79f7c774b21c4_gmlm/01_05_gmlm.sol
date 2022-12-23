// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM!LM!
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    (*'-'*)    //
//               //
//               //
///////////////////


contract gmlm is ERC721Creator {
    constructor() ERC721Creator("GM!LM!", "gmlm") {}
}