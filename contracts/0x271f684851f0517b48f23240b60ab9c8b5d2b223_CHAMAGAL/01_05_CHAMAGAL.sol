// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GALS’ ADVENTURE - CHAMAKOU GALVERSE ART MATSURI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    (づ˘ ³˘)づ *･ﾟ💌    //
//                      //
//                      //
//////////////////////////


contract CHAMAGAL is ERC1155Creator {
    constructor() ERC1155Creator(unicode"GALS’ ADVENTURE - CHAMAKOU GALVERSE ART MATSURI", "CHAMAGAL") {}
}