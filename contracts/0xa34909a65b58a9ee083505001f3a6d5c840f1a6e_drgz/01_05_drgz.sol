// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: drugs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Kenny Schachter    //
//                       //
//                       //
///////////////////////////


contract drgz is ERC721Creator {
    constructor() ERC721Creator("drugs", "drgz") {}
}