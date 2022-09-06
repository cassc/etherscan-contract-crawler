// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: thangka
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Oriental thangka    //
//                        //
//                        //
////////////////////////////


contract thangka is ERC721Creator {
    constructor() ERC721Creator("thangka", "thangka") {}
}