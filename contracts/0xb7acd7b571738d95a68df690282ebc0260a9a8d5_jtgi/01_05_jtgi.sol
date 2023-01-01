// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: jtgi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    gm    //
//          //
//          //
//////////////


contract jtgi is ERC721Creator {
    constructor() ERC721Creator("jtgi", "jtgi") {}
}