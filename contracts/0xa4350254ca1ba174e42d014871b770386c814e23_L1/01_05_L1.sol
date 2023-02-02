// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: L1berty
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//     (                   //
//    (_)                  //
//    ###       .          //
//    (#c    __\|/__       //
//     #\     wWWWw        //
//     \ \-. (/. .\)       //
//     /\ /`\/\   /\       //
//     |\/   \_) (_|       //
//     `\.' ; ; `' ;`\     //
//       `\;  ;    .  ;    //
//                         //
//                         //
/////////////////////////////


contract L1 is ERC721Creator {
    constructor() ERC721Creator("L1berty", "L1") {}
}