// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Corporate Śūnyatā
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    ((((((((((((((((((((((((((((((((((((((((((((((((((    //
//    ((((((((((((((((((((((((((((((((((((((((((((((((((    //
//    (((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((    //
//    (((@@@,,,[email protected]/,,&#....,..........(@@@((    //
//    (((@@@..............#[email protected]*@@@((    //
//    (((@@@.......,....&.............. ..........,@@@((    //
//    (((@@@........................ [email protected]@@((    //
//    (((@@@[email protected]@@@((    //
//    (((@@@...........%(//////////***** [email protected]@@((    //
//    (((@@@.,,.,..,,,../,/,[email protected]#./..#..,@[email protected]@@((    //
//    (((@@@....... QUANTUM COMMUNICATIONS,.......,@@@((    //
//    (((@@@.,............,%#%%%%%%& .............*@@@((    //
//    (((@@@.,..&%@@%&@&% *.&@,.*.#&..#. &#&&&&...(@@@((    //
//    (((@@@,,.....,...#/,.,,*/*,*..*..*..(.......&@@@((    //
//    (((@@@/......,............,............,[email protected]@@@((    //
//    (((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((    //
//    (((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((    //
//    (((%@@@@@@@@@@@@@@@@@@@@@@@@@@#@(@&@@@@@@@@@@@@#((    //
//    (((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((((((    //
//    ((((((((((((((((((((((((((((((((((((((((((((((((((    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract CS is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Corporate Śūnyatā", "CS") {}
}