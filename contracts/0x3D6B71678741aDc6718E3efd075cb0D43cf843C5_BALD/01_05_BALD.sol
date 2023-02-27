// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: #001 Bald Punk
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooolloooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooolooolllllllllllllllllllllllllllllllloooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooollooc..............................:oooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooollll:.                            .;lllloooooloooooooooooooooooooooo    //
//    oooooooooooooooooooooooooooooooo:...'cooooooooooooooooooooooooooool,...;lolooooooooooooooooooooooooo    //
//    ooooooooooooooooooooooooloooolll;   .xKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'   ,lllloooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool:...,clld0KKKKKKKKKKKKKKKKKKKKXXNNXXKK0dlll,...;looloooooooooooooooooooo    //
//    oooooooooooooooooooooooolool,   'kXKKKKKKKKKKKKKKKKKKKKKKKXNWNNXKKKKKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKKKKKXXXXXNNNXXKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKXNNNNXKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO,   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKK00000000KKKKKKKKKKKKKK00000000KKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKK0OkOkkOkO0KKKKKKKKKKKK0OkOOkkkO0KKO;   'looooooooooooooooooooooo    //
//    ooooooooooooooooooooloolc;;;,'''cOKKOocccccclkKKKKKKKKKKKKOoccccccoOKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooool'   ,OKKKKKKx.      .lKKKKKKKKKKKKd.      .dKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooool'   ;OKKKKKKk;......,dKKKKKKKKKKKKx,......,xKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooool'   ;OKKKKKKK00000000KKKKKKKKKKKKKK00000000KKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooool'   'dxxOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooool'       ;OKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooool,.      'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooolccc'   'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKK0OOOOOOOOOOOOKKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKo'..........,xKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKl.          .oKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKOxddddddc.  .oKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKx.  .dKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKKKKKKKKK0xoodOKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO;   'looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o;;;,'',:looooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'   ,looooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKK0d:::::::::::::::::::::,'',:oooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKO;                     ;oooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKO;   .................'coooolooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKO;   'cloooooooooooooooloolloooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKO;   'cloooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKO;   'cloooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooooooooool,   'kKKKKKKKKKKO;   'cloooooooooooooooooooooooooooooooooooooooooooooooo    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BALD is ERC721Creator {
    constructor() ERC721Creator("#001 Bald Punk", "BALD") {}
}