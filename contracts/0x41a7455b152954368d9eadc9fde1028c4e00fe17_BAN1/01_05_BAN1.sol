// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Barry Alaskans 1/1 NFTS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//    .s5SSSs.                                            .s5SSSs.                                                                                .s    s.  .s5SSSs. .s5SSSSs. .s5SSSs.      //
//          SS. .s5SSSs.  .s5SSSs.  .s5SSSs.  .s5 s.            SS. .s        .s5SSSs.  .s5SSSs.  .s    s.  .s5SSSs.  .s    s.  .s5SSSs.                SS.             SSS          SS.     //
//    sS    S%S       SS.       SS.       SS.     SS.     sS    S%S                 SS.       SS.       SS.       SS.       SS.       SS.         sSs.  S%S sS          S%S    sS    `:;     //
//    SS    S%S sS    S%S sS    S%S sS    S%S ssS SSS     SS    S%S sS        sS    S%S sS    `:; sS    S%S sS    S%S sSs.  S%S sS    `:;         SS`S. S%S SS          S%S    SS            //
//    SS .sSSS  SSSs. S%S SS .sS;:' SS .sS;:'  SSSSS      SSSs. S%S SS        SSSs. S%S `:;;;;.   SSSSs.S:' SSSs. S%S SS `S.S%S `:;;;;.           SS `S.S%S SSSs.       S%S    `:;;;;.       //
//    SS    S%S SS    S%S SS    ;,  SS    ;,    SSS       SS    S%S SS        SS    S%S       ;;. SS  "SS.  SS    S%S SS  `sS%S       ;;.         SS  `sS%S SS          S%S          ;;.     //
//    SS    `:; SS    `:; SS    `:; SS    `:;   `:;       SS    `:; SS        SS    `:;       `:; SS    `:; SS    `:; SS    `:;       `:;         SS    `:; SS          `:;          `:;     //
//    SS    ;,. SS    ;,. SS    ;,. SS    ;,.   ;,.       SS    ;,. SS    ;,. SS    ;,. .,;   ;,. SS    ;,. SS    ;,. SS    ;,. .,;   ;,.         SS    ;,. SS          ;,.    .,;   ;,.     //
//    `:;;;;;:' :;    ;:' `:    ;:' `:    ;:'   ;:'       :;    ;:' `:;;;;;:' :;    ;:' `:;;;;;:' :;    ;:' :;    ;:' :;    ;:' `:;;;;;:'         :;    ;:' :;          ;:'    `:;;;;;:'     //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BAN1 is ERC721Creator {
    constructor() ERC721Creator("Barry Alaskans 1/1 NFTS", "BAN1") {}
}