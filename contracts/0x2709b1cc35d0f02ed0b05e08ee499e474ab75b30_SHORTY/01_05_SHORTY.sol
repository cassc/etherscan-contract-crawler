// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shorty the Cat
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//                       ;,_            ,                                                         //
//                     _uP~"b          d"u,                                                       //
//                    dP'   "b       ,d"  "o                                                      //
//                   d"    , `b     d"'    "b                                                     //
//                  l] [    " `l,  d"       lb                                                    //
//                  Ol ?     "  "b`"=uoqo,_  "l                                                   //
//                ,dBb "b        "b,    `"~~TObup,_                                               //
//              ,d" (db.`"         ""     "tbc,_ `~"Yuu,_                                         //
//            .d" l`T'  '=                      ~     `""Yu,                                      //
//          ,dO` gP,                           `u,   b,_  "b7                                     //
//         d?' ,d" l,                           `"b,_ `~b  "1                                     //
//       ,8i' dl   `l                 ,ggQOV",dbgq,._"  `l  lb                                    //
//      .df' (O,    "             ,ggQY"~  , @@@@@d"bd~  `b "1                                    //
//     .df'   `"           [email protected]""     (b  @@@@P db    `Lp"b,                                  //
//    .d(                  _               "ko "=d_,Q`  ,_  "  "b,                                //
//    Ql         .         `"qo,._          "tQo,_`""bo ;tb,    `"b,                              //
//    qQ         |L           ~"QQQgggc,_.,dObc,opooO  `"~~";.   __,7,                            //
//    qp         t\io,_           `~"TOOggQV""""        _,dg,_ =PIQHib.                           //
//    `qp        `Q["tQQQo,_                          ,pl{QOP"'   7AFR`                           //
//      `         `tb  '""tQQQg,_             p" "b   `       .;-.`Vl'                            //
//                 "Yb      `"tQOOo,__    _,edb    ` .__   /`/'|  |b;=;.__                        //
//                               `"tQQQOOOOP""`"\QV;qQObob"`-._`\_~~-._                           //
//                                    """"    ._        /   | |oP"\_   ~\ ~\_~\                   //
//                                            `~"\ic,qggddOOP"|  |  ~\   `\~-._                   //
//                                              ,qP`"""|"   | `\ `;   `\   `\                     //
//                                   _        _,p"     |    |   `\`;    |    |                    //
//                                   "boo,._dP"       `\_  `\    `\|   `\   ;                     //
//                                     `"7tY~'            `\  `\    `|_   |                       //
//                                                          `~\  |                                //
//                                                                                                //
//    Thank you for checking out the Shorty Collection.  The Shorty collection                    //
//    features my Maine Coon Shorty and all his adventures with photos spanning back as far       //
//    as 2010 when I adopted him as a kitten. Shorty has been a grand part of my life and         //
//    I'm always happy to share his adventures to the world.  This collection will be limited     //
//    to 100 pieces.                                                                              //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract SHORTY is ERC721Creator {
    constructor() ERC721Creator("Shorty the Cat", "SHORTY") {}
}