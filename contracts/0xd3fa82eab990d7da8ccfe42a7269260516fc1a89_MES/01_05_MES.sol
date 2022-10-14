// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Machine Elf Shaman Special Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                            //
//                                                                                                                            ,                                                                                                               //
//                                                                                                                            Et                                                                                                              //
//                                              .,                 L.                     ,;               ,;                 E#t                     .                                                          L.                      .    //
//                                             ,Wt .    .      t   EW:        ,ft       f#i              f#i            i     E##t                   ;W.    .                                                    EW:        ,ft         ;W    //
//                ..       :           ..     i#D. Di   Dt     Ej  E##;       t#E     .E#t             .E#t            LE     E#W#t                 f#EDi   Dt              ..           ..       :           .. E##;       t#E        f#E    //
//               ,W,     .Et          ;W,    f#f   E#i  E#i    E#, E###t      t#E    i#W,             i#W,            L#E     E#tfL.              .E#f E#i  E#i            ;W,          ,W,     .Et          ;W, E###t      t#E      .E#f     //
//              t##,    ,W#t         j##,  .D#i    E#t  E#t    E#t E#fE#f     t#E   L#D.             L#D.            G#W.     E#t                iWW;  E#t  E#t           j##,         t##,    ,W#t         j##, E#fE#f     t#E     iWW;      //
//             L###,   j###t        G###, :KW,     E#t  E#t    E#t E#t D#G    t#E :K#Wfff;         :K#Wfff;         D#K.   ,ffW#Dffj.           L##LffiE#t  E#t          G###,        L###,   j###t        G###, E#t D#G    t#E    L##Lffi    //
//           .E#j##,  G#fE#t      :E####, t#f      E########f. E#t E#t  f#E.  t#E i##WLLLLt        i##WLLLLt       E#K.     ;LW#ELLLf.         tLLG##L E########f.     :E####,      .E#j##,  G#fE#t      :E####, E#t  f#E.  t#E   tLLG##L     //
//          ;WW; ##,:K#i E#t     ;W#DG##,  ;#G     E#j..K#j... E#t E#t   t#K: t#E  .E#L             .E#L         .E#E.        E#t                ,W#i  E#j..K#j...    ;W#DG##,     ;WW; ##,:K#i E#t     ;W#DG##, E#t   t#K: t#E     ,W#i      //
//         j#E.  ##f#W,  E#t    j###DW##,   :KE.   E#t  E#t    E#t E#t    ;#W,t#E    f#E:             f#E:      .K#E          E#t               j#E.   E#t  E#t      j###DW##,    j#E.  ##f#W,  E#t    j###DW##, E#t    ;#W,t#E    j#E.       //
//       .D#L    ###K:   E#t   G##i,,G##,    .DW:  E#t  E#t    E#t E#t     :K#D#E     ,WW;             ,WW;    .K#D           E#t             .D#j     E#t  E#t     G##i,,G##,  .D#L    ###K:   E#t   G##i,,G##, E#t     :K#D#E  .D#j         //
//      :K#t     ##D.    E#t :K#K:   L##,      L#, f#t  f#t    E#t E#t      .E##E      .D#;             .D#;  .W#G            E#t            ,WK,      f#t  f#t   :K#K:   L##, :K#t     ##D.    E#t :K#K:   L##, E#t      .E##E ,WK,          //
//      ...      #G      .. ;##D.    L##,       jt  ii   ii    E#t ..         G#E        tt               tt :W##########Wt   E#t            EG.        ii   ii  ;##D.    L##, ...      #G      .. ;##D.    L##, ..         G#E EG.           //
//               j          ,,,      .,,                       ,;.             fE                            :,,,,,,,,,,,,,.  ;#t            ,                   ,,,      .,,           j          ,,,      .,,              fE ,             //
//                                                                              ,                                              :;                                                                                             ,               //
//                                                         ;                                                                                                                                                                                  //
//                                                         ED.                                            :                                                                                                                                   //
//                                   :      L.             E#Wi                 ,;                       t#,                                                                                                                                  //
//      .                            Ef     EW:        ,ft E###G.             f#i j.                    ;##W.                                                                                                                                 //
//      Ef.        f.     ;WE.       E#t    E##;       t#E E#fD#W;          .E#t  EW,       GEEEEEEEL  :#L:WE             ;                                                                                                                   //
//      E#Wi       E#,   i#G         E#t    E###t      t#E E#t t##L        i#W,   E##j      ,;;L#K;;. .KG  ,#D          .DL                                                                                                                   //
//      E#K#D:     E#t  f#f          E#t    E#fE#f     t#E E#t  .E#K,     L#D.    E###D.       t#E    EE    ;#f f.     :K#L     LWL                                                                                                           //
//      E#t,E#f.   E#t G#i           E#t fi E#t D#G    t#E E#t    j##f  :K#Wfff;  E#jG#W;      t#E   f#.     t#iEW:   ;W##L   .E#f                                                                                                            //
//      E#WEE##Wt  E#jEW,            E#t L#jE#t  f#E.  t#E E#t    :E#K: i##WLLLLt E#t t##f     t#E   :#G     GK E#t  t#KE#L  ,W#;                                                                                                             //
//      E##Ei;;;;. E##E.             E#t L#LE#t   t#K: t#E E#t   t##L    .E#L     E#t  :K#E:   t#E    ;#L   LW. E#t f#D.L#L t#K:                                                                                                              //
//      E#DWWt     E#G               E#tf#E:E#t    ;#W,t#E E#t .D#W;       f#E:   E#KDDDD###i  t#E     t#f f#:  E#jG#f  L#LL#G                                                                                                                //
//      E#t f#K;   E#t               E###f  E#t     :K#D#E E#tiW#G.         ,WW;  E#f,t#Wi,,,  t#E      f#D#;   E###;   L###j                                                                                                                 //
//      E#Dfff##E, E#t               E#K,   E#t      .E##E E#K##i            .D#; E#t  ;#W:    t#E       G#t    E#K:    L#W;                                                                                                                  //
//      jLLLLLLLLL;EE.               EL     ..         G#E E##D.               tt DWi   ,KK:    fE        t     EG      LE.                                                                                                                   //
//                 t                 :                  fE E#t                                   :              ;       ;@                                                                                                                    //
//                                                       , L:                                                                                                                                                                                 //
//                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MES is ERC1155Creator {
    constructor() ERC1155Creator() {}
}