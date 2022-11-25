// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: denzuul
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    denzuul made it    //
//                       //
//                       //
///////////////////////////


contract DENZ is ERC721Creator {
    constructor() ERC721Creator("denzuul", "DENZ") {}
}