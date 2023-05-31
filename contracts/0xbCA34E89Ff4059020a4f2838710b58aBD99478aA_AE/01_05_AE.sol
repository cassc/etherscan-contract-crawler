// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arino’s Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    (๑>◡<๑)٩( ᐛ )و    //
//                      //
//                      //
//////////////////////////


contract AE is ERC721Creator {
    constructor() ERC721Creator(unicode"Arino’s Edition", "AE") {}
}