// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UNWOVEN WEB
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                               .,.                                            //
//                                                                                                            'cdkxl.                                           //
//                                                                                                          .dK0o..;c.                                          //
//                                                                                                        .:O0l.    :l.                                         //
//                                                                                                      .;xOo'       :o.                                        //
//                                                                                                   .,oO0o'         .co.                                       //
//                                                                                                  .oKKd'            .co.                                      //
//                                                                                                 .lko,               .lo.                                     //
//                           ','',,,,,,,,,,,,'''''''.....'''''''.                                  ;dc.                 .lc.                                    //
//                          .l:.....''''''''''''''''''',,'',,,;ol;.                               .cc.                   ':.                                    //
//                          .l'                                .cdd:.                             ;l'                    .;.                                    //
//                          ,l.                                  ;do,    ..',,,.                 .c:.                    .,.                                    //
//                          :c.                                  .ldc. .ckKKXXX0l:'             .:oc'                    .,.                                    //
//                         .c:                                    :xdclkKKKKXXXNNNKx;.          ;xdxx;                   .'                                     //
//                         .l'                                    'dxxkO00KKKKXXXXXNXd.        .cd;.co;.                 ..                                     //
//                         'c.                                    .lkxkOOOO00KKKKXXXXXd.       ;oo, .co:.                                                       //
//                         ,:.                                     ;kkxkOOOO00KKKKKKKXXd.     .loo,  .:o:.                                                      //
//                         ;,                          ......'',,;;lkkxxkOOOO00KKKKKKKKKc    .:ooo,   .:oc. .;::c:.                                             //
//                       .,c'         ..',,;;;;;;,;;:::cccccccc:::;cxOkkOkkOOOO00KKKKKKKd.   ;lodd,    .:dooxkkkOOxc,.                                          //
//                     .,,'.      ..,,;,'',''''............         ;O0000OOkOOO0KK0000Kd.  ,ooodx;     .oOkkkoc:,,cooc;,..                                     //
//                  .....    ..'',,'..                             'cxOOO0OkkkOOOOOO0000l. ,odlcdk:    .:kOOkc.    .;lc;,;:::;,.                                //
//                       .......                                 .;c;:xOOOOkkkkkkOOO000O; 'odd::xkc   .okOdldd,      .:c'. .';lx,                               //
//                   ......                                    .;:;.  ckkOOkkOOOOOOO000l..odxl'ckOc..cxOkl. 'lo'      .,c:.   .dl                               //
//                  ..                                       .;:;.    'xOOkkkOOOkOOO00x..oddx,.okkxoxOOx;    .cc'       .:c;.  ld.                              //
//                                                         .;:;.      .oOOkkkkOkkOO00KOdkOxxl.'xOOOkkOo.      .;c.        'cc,.;k,                              //
//                                                       .;c;.        .ckOxddkOkkkO0KKKXXK0kocx0OOkkkc.        .::.        .;l:cx;                              //
//                                                     .,c:.           :OOOxxOOkkkkO00KKKK00OxkOOOkd'           ;l'          .:od,                              //
//                                                    'cc'.            'dOOkOOkxxdxkkkO0K00OxxkOOkc.            .c;            ,ll'                             //
//                                                  .:c,.              .lkkkOOkxdodkkkkOOOOOxkkkkl.             .;:.            .:l,                            //
//                                                .;:,.                 .'lkkOkdooxkkkkkkOOxxOOOx,               'c'             .;c,                           //
//                                               ':;.                     .cx00xodxkkkkkxkkxkOd:.                .:;.             .;c.                          //
//                                             .;;'                         ',:ooloxxdxxdxxlcdc.                  ,c.              .;:.                         //
//                                            .,,.                            .:;..'coolodo;,,.                   .c,               .;:.                        //
//                                          .',.                              ':.   .c,.',;:.                      ;:.               .;;.                       //
//                                         .,'.                              .;;.    .'  .,.                       .c'                .:;.                      //
//                                       .',.                                .:,                                   .;;.                .:;.                     //
//                                      .,'.                                 ':.                                    ':.                 .:;.                    //
//                                    .,,.                                  .,;.                                    .:,                  .:;.                   //
//                                   ';,.                                   .;'                                      ,:.                  .:;.                  //
//                                 .;:.                                     .;.                                      .:,                   .c;.                 //
//                               .,:,.                                      ''                                        ,:.                   .c:.                //
//                              .:;.                                       .,.                                        .:,                    .c:.               //
//                             ,:,                                         .,.                                         ;:.                    .c:               //
//                            ,;.                                          .'                                          ,:.                     .c;              //
//                          .;,.                                          .'.                                          ;;                       .c,             //
//                         .;.                                            .,.                                          ;'                        .:'            //
//                        ',.                                             ''                                           ,.                         .,.           //
//                       ..                                              .,.                                           '.                          ...          //
//                                                                       .,.                                           .                                        //
//                                                                       ,'                                                                                     //
//                                                                      .;.                                                                                     //
//                                                                      .;.                                                                                     //
//                                                                      ,;                                                                                      //
//                                                                     .:'                                                                                      //
//                                                                     .:.                                                                                      //
//                                                                     .'                                                                                       //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//    Back to start                                                                                                                                             //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UWN is ERC721Creator {
    constructor() ERC721Creator("UNWOVEN WEB", "UWN") {}
}