// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Doodle Dix
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    Doodle Dix the small collection    //
//                                       //
//                                       //
///////////////////////////////////////////


contract DoDi is ERC721Creator {
    constructor() ERC721Creator("Doodle Dix", "DoDi") {}
}