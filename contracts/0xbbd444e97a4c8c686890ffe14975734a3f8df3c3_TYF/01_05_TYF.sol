// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ty Fortune
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//                                    ,                                                                         //
//                                    Et           :                                                            //
//                                    E#t         t#,                       :      L.                     ,;    //
//                                    E##t       ;##W.   j.                 Ef     EW:        ,ft       f#i     //
//      GEEEEEEELf.     ;WE.          E#W#t     :#L:WE   EW,       GEEEEEEELE#t    E##;       t#E     .E#t      //
//      ,;;L#K;;.E#,   i#G            E#tfL.   .KG  ,#D  E##j      ,;;L#K;;.E#t    E###t      t#E    i#W,       //
//         t#E   E#t  f#f             E#t      EE    ;#f E###D.       t#E   E#t    E#fE#f     t#E   L#D.        //
//         t#E   E#t G#i           ,ffW#Dffj. f#.     t#iE#jG#W;      t#E   E#t fi E#t D#G    t#E :K#Wfff;      //
//         t#E   E#jEW,             ;LW#ELLLf.:#G     GK E#t t##f     t#E   E#t L#jE#t  f#E.  t#E i##WLLLLt     //
//         t#E   E##E.                E#t      ;#L   LW. E#t  :K#E:   t#E   E#t L#LE#t   t#K: t#E  .E#L         //
//         t#E   E#G                  E#t       t#f f#:  E#KDDDD###i  t#E   E#tf#E:E#t    ;#W,t#E    f#E:       //
//         t#E   E#t                  E#t        f#D#;   E#f,t#Wi,,,  t#E   E###f  E#t     :K#D#E     ,WW;      //
//         t#E   E#t                  E#t         G#t    E#t  ;#W:    t#E   E#K,   E#t      .E##E      .D#;     //
//          fE   EE.                  E#t          t     DWi   ,KK:    fE   EL     ..         G#E        tt     //
//           :   t                    ;#t                               :   :                  fE               //
//                                     :;                                                       ,               //
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TYF is ERC721Creator {
    constructor() ERC721Creator("Ty Fortune", "TYF") {}
}