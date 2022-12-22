// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In Stitches
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//      ___        __,                          //
//     ( /        (    _/_o _/_    /            //
//      / _ _      `.  / ,  /  _, /_  _  (      //
//    _/_/ / /_  (___)(__(_(__(__/ /_(/_/_)_    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract Stitches is ERC721Creator {
    constructor() ERC721Creator("In Stitches", "Stitches") {}
}