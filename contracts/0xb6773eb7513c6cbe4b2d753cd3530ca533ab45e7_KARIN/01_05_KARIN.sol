// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KARINDROPS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                          .i.,.                                        //
//                                       `.J:~~~?TS,.                                    //
//        `  `  `  `  `  `  `  `  JTu.. .TSJ~~~~~~~~?5,   `  `  `  `  `  `  `  `  `      //
//                                 Tg_?W+.` 7G,~~~~~~~(]                                 //
//                                   TNJ_?5+,`.74J_~~~j!                                 //
//       `                             MMNx.?T6aduB9HWF     `                            //
//          `  `  `  `  `  `  `       .MMMMMMNXqt(b~~(#zvTT"=H   `  `  `  `  `  `  `     //
//                                   ,MMMMMMMNJ>~(bh(dWg&+J+JT                           //
//                               `    dMMMMMMMMNNMMmY76aWa...                            //
//       `                             """7MMM#WMMMMMmJ_~~~(P                            //
//          `  `  `  `  `  `  `         .JTB?B?EH?MMMNkWMTOd:.v`   `  `  `  `  `  `      //
//                                `    .JBaV=<XfN,,L.Tb_7M"^`                            //
//                                 ..Z^....W_.Rt(#+K  ?| d                               //
//       `                       (=(!.....(#.._.(F(9TS.%.t         `                     //
//          `  `  `  `  `  `  `  d+$.....(@~..~.(F~~~~W         `      `  `  `  `  `     //
//                             .+MMMJ.-(d3..~..~(b~~~~d.    `                            //
//                         .(MMMM"^   (@_..~.....de(JMMN,              ..                //
//       `             .MMMM#"!      J3..~..~.~.~(#   TMMN,    `   ` .dBTm,              //
//          `  `  `    [email protected]          W/...~..~...(%     7MMm.  `   .MHZWWZMm, `  `       //
//                   `               .NJ---(---(J^        (WMM#"N.Mh<dHZZZZyMm.          //
//                                   ?1p.x(x(/(Jd`         .MB3-MUzzWxBTmZZyZXMe         //
//       `        `                  .dMcd~~~~~d\           .MBvvzzzzXN+?WkZZZZHM,  `    //
//          `  `                  `.d5~?bJ:~~~(@          .#UNyvzzzzzzzWmjgHkZZNg#!      //
//                   `  `  `  `  .d6~~~(MD:~:~Jb     ` .(MWHeqHmzzzzzzzzwHx;?Hq#'        //
//                             .#>~~:(J"(N~~~~_N.     .Nd#ZZUNyvWmzzzzzzzzXNj#'          //
//                          .J8<~~(J#^   dp~:~~d]      [email protected]!            //
//                        .#=~~~(g"`      Te_~~(N.       ?NXZZZXMd6TmzzQ#"               //
//               .uWa,  ..Mp:(JT'          .WJ~~(W,       .URyZZZWNzvNM=                 //
//               WdRtdNMMM#"7^               ?N-~~?N,       (NkZZyZM#^                   //
//                S#NydB=                     .Ue:~_H|        TNdNY'                     //
//                 (N&F                         ?N&g#           "                        //
//                                                 WMp                                   //
//                                                  MMTa,                                //
//                                                 .6ug#d`                               //
//                                                .N#dK"`                                //
//                                                ."^                                    //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract KARIN is ERC1155Creator {
    constructor() ERC1155Creator("KARINDROPS", "KARIN") {}
}