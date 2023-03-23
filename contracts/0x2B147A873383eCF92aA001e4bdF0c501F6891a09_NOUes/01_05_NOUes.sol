// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: epistolary studies
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                               _                   //
//      _  ,_    .  ,   -/- _,_ // __,   ,_          //
//    _(/__/_)__/__/_)__/__(_/_(/_(_/(__/ (__(_/_    //
//        /                                  _/_     //
//       /                                  (/       //
//                                                   //
//                                                   //
//      ,   -/-      __/   .  _   ,                  //
//    _/_)__/__(_/__(_/(__/__(/__/_)_                //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract NOUes is ERC721Creator {
    constructor() ERC721Creator("epistolary studies", "NOUes") {}
}