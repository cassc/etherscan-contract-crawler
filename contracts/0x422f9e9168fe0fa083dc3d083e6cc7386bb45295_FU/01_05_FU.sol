// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FLIP BIRD - FU Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//    .s5SSSs. .s    s.  .s5SSSs.  .s    s.      .s5 s.  .s5SSSs.  .s    s.      //
//                   SS.       SS.       SS.         SS.       SS.       SS.     //
//    sS       sS    S%S sS    `:; sS    S%S     ssS SSS sS    S%S sS    S%S     //
//    SS       SS    S%S SS        SS    S%S     SSS SSS SS    S%S SS    S%S     //
//    SSSs.    SS    S%S SS        SSSSs.S:'      SSSSS  SS    S%S SS    S%S     //
//    SS       SS    S%S SS        SS  "SS.        SSS   SS    S%S SS    S%S     //
//    SS       SS    `:; SS        SS    `:;       `:;   SS    `:; SS    `:;     //
//    SS       SS    ;,. SS    ;,. SS    ;,.       ;,.   SS    ;,. SS    ;,.     //
//    :;       `:;;;;;:' `:;;;;;:' :;    ;:'       ;:'   `:;;;;;:' `:;;;;;:'     //
//                                                                               //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract FU is ERC721Creator {
    constructor() ERC721Creator("FLIP BIRD - FU Edition", "FU") {}
}