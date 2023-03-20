// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: G.Kate - Dolls Katti&Kate
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//       ____      _  __      _       _____  U _____ u                             //
//    U /"___|u   |"|/ /  U  /"\  u  |_ " _| \| ___"|/                             //
//    \| |  _ /   | ' /    \/ _ \/     | |    |  _|"                               //
//     | |_| |  U/| . \\u  / ___ \    /| |\   | |___                               //
//      \____|_   |_|\_\  /_/   \_\  u |_|U   |_____|                              //
//      _)(|_("),-,>> \\,-.\\    >>  _// \\_  <<   >>                              //
//     (__)__)"  \.)   (_/(__)  (__)(__) (__)(__) (__)                             //
//                                                                                 //
//                                                                                 //
//    Creator: Katerina Gutyro                                                     //
//                                                                                 //
//    When you purchase an art, all rights of ownership are transferred to you.    //
//                                                                                 //
//    Thank you for your purchase.                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract GK is ERC721Creator {
    constructor() ERC721Creator("G.Kate - Dolls Katti&Kate", "GK") {}
}