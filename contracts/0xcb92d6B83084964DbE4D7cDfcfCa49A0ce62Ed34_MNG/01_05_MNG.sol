// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: theonly_mango
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    ( ╯°Д°）╯︵ ┻━┻     //
//    Mango was here    //
//                      //
//                      //
//////////////////////////


contract MNG is ERC721Creator {
    constructor() ERC721Creator("theonly_mango", "MNG") {}
}