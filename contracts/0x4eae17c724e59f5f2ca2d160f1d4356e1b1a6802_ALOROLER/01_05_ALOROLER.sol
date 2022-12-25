// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: aloroler
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Type: 1/1            //
//    Artist: aloroler     //
//    Control: Creative    //
//                         //
//                         //
/////////////////////////////


contract ALOROLER is ERC721Creator {
    constructor() ERC721Creator("aloroler", "ALOROLER") {}
}