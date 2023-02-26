// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: diaspora
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    diaspora    //
//                //
//                //
////////////////////


contract dia is ERC721Creator {
    constructor() ERC721Creator("diaspora", "dia") {}
}