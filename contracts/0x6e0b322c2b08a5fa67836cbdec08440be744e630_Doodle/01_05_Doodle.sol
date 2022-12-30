// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DoodleStreet
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Doodle Street NFTs    //
//                          //
//                          //
//////////////////////////////


contract Doodle is ERC721Creator {
    constructor() ERC721Creator("DoodleStreet", "Doodle") {}
}