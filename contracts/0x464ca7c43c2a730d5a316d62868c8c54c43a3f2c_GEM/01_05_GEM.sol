// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gemini Rising
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    |||||        //
//    ||. .||      //
//    |||\=/|||    //
//    |.-- --.|    //
//    /(.) (.)\    //
//    \ ) . ( /    //
//    '( v )`      //
//    \ | /        //
//    ( | )        //
//    '- -`        //
//                 //
//                 //
/////////////////////


contract GEM is ERC721Creator {
    constructor() ERC721Creator("Gemini Rising", "GEM") {}
}