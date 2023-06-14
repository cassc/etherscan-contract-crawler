// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spoons
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//     ___                                         //
//    (  _`\                                       //
//    | (_(_) _ _      _      _     ___    ___     //
//    `\__ \ ( '_`\  /'_`\  /'_`\ /' _ `\/',__)    //
//    ( )_) || (_) )( (_) )( (_) )| ( ) |\__, \    //
//    `\____)| ,__/'`\___/'`\___/'(_) (_)(____/    //
//           | |                                   //
//           (_)                                   //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract SPNS is ERC721Creator {
    constructor() ERC721Creator("Spoons", "SPNS") {}
}