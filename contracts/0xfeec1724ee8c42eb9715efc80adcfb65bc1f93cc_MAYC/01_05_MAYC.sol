// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mutant Ape Yacht Club‎
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//          ."`".          //
//      .-./ _=_ \.-.      //
//     {  (,(oYo),) }}     //
//     {{ |   "   |} }     //
//     { { \(---)/  }}     //
//     {{  }'-=-'{ } }     //
//     { { }._:_.{  }}     //
//     {{  } -:- { } }     //
//     {_{ }`===`{  _}     //
//    ((((\)     (/))))    //
//                         //
//                         //
/////////////////////////////


contract MAYC is ERC721Creator {
    constructor() ERC721Creator(unicode"Mutant Ape Yacht Club‎", "MAYC") {}
}