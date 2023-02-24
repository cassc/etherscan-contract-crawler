// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wolf Pack
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                    ,                                                       //
//                              :                     Et                                                      //
//                             t#,                    E#t                                       .,G:          //
//                            ;##W.             i     E##t           t                         ,WtE#,    :    //
//                ;          :#L:WE            LE     E#W#t          ED.               ..     i#D.E#t  .GE    //
//              .DL         .KG  ,#D          L#E     E#tfL.         E#K:             ;W,    f#f  E#t j#K;    //
//      f.     :K#L     LWL EE    ;#f        G#W.     E#t            E##W;           j##,  .D#i   E#GK#f      //
//      EW:   ;W##L   .E#f f#.     t#i      D#K.   ,ffW#Dffj.        E#E##t         G###, :KW,    E##D.       //
//      E#t  t#KE#L  ,W#;  :#G     GK      E#K.     ;LW#ELLLf.       E#ti##f      :E####, t#f     E##Wi       //
//      E#t f#D.L#L t#K:    ;#L   LW.    .E#E.        E#t            E#t ;##D.   ;W#DG##,  ;#G    E#jL#D:     //
//      E#jG#f  L#LL#G       t#f f#:    .K#E          E#t            E#ELLE##K: j###DW##,   :KE.  E#t ,K#j    //
//      E###;   L###j         f#D#;    .K#D           E#t            E#L;;;;;;,G##i,,G##,    .DW: E#t   jD    //
//      E#K:    L#W;           G#t    .W#G            E#t            E#t     :K#K:   L##,      L#,j#t         //
//      EG      LE.             t    :W##########Wt   E#t            E#t    ;##D.    L##,       jt ,;         //
//      ;       ;@                   :,,,,,,,,,,,,,.  ;#t                   ,,,      .,,                      //
//                                                     :;                                                     //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WLFP is ERC721Creator {
    constructor() ERC721Creator("Wolf Pack", "WLFP") {}
}