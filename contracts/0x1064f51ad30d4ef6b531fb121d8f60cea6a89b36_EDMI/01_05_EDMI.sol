// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evelixia Design Museum I
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//     / \------------,     //
//     \_,|           |     //
//        |    SMDM   |     //
//        |  ,----------    //
//        \_/_________/     //
//                          //
//                          //
//////////////////////////////


contract EDMI is ERC721Creator {
    constructor() ERC721Creator("Evelixia Design Museum I", "EDMI") {}
}