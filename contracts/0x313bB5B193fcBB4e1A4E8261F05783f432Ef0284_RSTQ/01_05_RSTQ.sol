// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Red Summoner - 2nd drop
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//      ,        ,,                                         //
//     ||    _   ||  '              '                       //
//    =||=  < \, || \\  /'\\ \\/\\ \\  /'\\ \\ \\  _-_      //
//     ||   /-|| || || || || || || || || || || || || \\     //
//     ||  (( || || || || || || || || || || || || ||/       //
//     \\,  \/\\ \\ \\ \\,/  \\ \\ \\ \\,|| \\/\\ \\,/      //
//                                       ||                 //
//                                       '`                 //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract RSTQ is ERC1155Creator {
    constructor() ERC1155Creator("Red Summoner - 2nd drop", "RSTQ") {}
}