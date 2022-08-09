// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PunkActual
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Punk Actual    //
//                   //
//                   //
///////////////////////


contract PunkA is ERC721Creator {
    constructor() ERC721Creator("PunkActual", "PunkA") {}
}