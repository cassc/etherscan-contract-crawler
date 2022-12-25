// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: section51
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//                                                                        //
//    .s5SSSs.  .s5SSSs.  .s5SSSs.  .s5SSSSs. s.  .s5SSSs.  .s    s.      //
//          SS.       SS.       SS.    SSS    SS.       SS.       SS.     //
//    sS    `:; sS    `:; sS    `:;    S%S    S%S sS    S%S sSs.  S%S     //
//    `:;;;;.   SSSs.     SS           S%S    S%S SS    S%S SS `S.S%S     //
//          ;;. SS        SS           S%S    S%S SS    S%S SS  `sS%S     //
//          `:; SS        SS           `:;    `:; SS    `:; SS    `:;     //
//    .,;   ;,. SS    ;,. SS    ;,.    ;,.    ;,. SS    ;,. SS    ;,.     //
//    `:;;;;;:' `:;;;;;:' `:;;;;;:'    ;:'    ;:' `:;;;;;:' :;    ;:'     //
//                                                                        //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract section51 is ERC1155Creator {
    constructor() ERC1155Creator("section51", "section51") {}
}