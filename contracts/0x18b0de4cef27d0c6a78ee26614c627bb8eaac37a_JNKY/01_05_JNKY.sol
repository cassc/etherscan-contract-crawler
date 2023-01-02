// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JUNKYARD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                      ..                         .                                              //
//                                                      ':.                       'l.                                             //
//                            ,;     .:.                :d.                       c0;    ,l.                                      //
//                            dO.    lk.               .xk.   ,;                 .kN:    ;0:                                      //
//                           .xWo   '0k.               ,KK,   c0,                cNNc    :Nk.                    .,c'             //
//                           .kMO.  :NK,               cWWd.  dMk.              .kMN:    dMWd. ..              .lOO;              //
//                           ;XMk.  :NWk.              lWMK, '0MWk:.            '0MWc   .kMMK,.l,            ,xXNx.               //
//                           dMMx.  ,KMWk.             :NMK, ;XMMWWO,           .OMMd   .OMMXdko           .lXMK:                 //
//                          .xMMk.  .OMMNc             ;XM0' ;XMMMMM0'          .kMM0'  .xMMWWk.          .dWM0,                  //
//                          .xMMK;  .OMMMd             cNMX; '0MMMMMWo     .     dMMWc   oMMMK;          .xWMX:                   //
//                      .'.  oMMMk. ,KMMMd            .kMMWo .xMMMMMMK,   ;;    .xMMMx.  cNMMk.         ;OWMXc                    //
//                     .oc   oMMMNc ;XMMMd       ,'   ;XMMMO..xMMMMMMMO'.dd.    'OMMMx.  :NMMX:      'oONMMK:                     //
//                     o0,  .kMMMMo ,KMMMk.      .lc. cWMMM0,.kMMMMMMMWKKk.     cNMMMd   cNMMMd    ,kNMMWKl.                      //
//                ;;  cXd   ,KMMMWl .kMMMNc       .xd.cWMMMO.'0MMMMMMMMMWk.    .xMMMWl   oMMMMx. .dNMMMXo.                        //
//               .kl ;KK,   ,KMMMN:  oWMMMx.       ;KxoXMMMx.'0MMMMMMMMMMWd.   '0MMMX;  .xMMMMO;c0WMMMNc                          //
//        ..     lWd,OWo    .OMMMN:  :NMMMk.        lNNWMMMo .xMMWXOKMMMMMN:   ,KMMM0'  .xMMMMWNWMMMMMK,                          //
//        cx.   .kMXKWK,     oWMMMx. cNMMMx.  .     .oNMMMMo  cNMNKc;KMMMMM0'  ,KMMMO.   oMMMMMMMMMMMMWd                          //
//        '0k.  .kMMMWo      ;XMMMX; lWMMMd.'l:      :XMMMMx. ,KMWNc .dXMMMM0c..OMMMK,   cNMMMMMMXkXMMMX:        .                //
//         cXx.  lWMMK,      '0MMMMl lMMMMKOKo.     .OMMMMMO. ;XMWNl   .oXMMMW0oOMMMNc   ;XMMMMM0, 'OMMMXl.    ;o,                //
//         .kNl  ;XMMk.      ;KMMMNc :NMMMMMK:     .dWMMMMMk. lWMKx,     ;KMMMMMWMMMMx.  :XMMMM0,   ;KMMMWO,.;O0:                 //
//          lWX: '0MMNd,....:0WMMMk. .xWMMMMMNkc;;lOWMMMMMNc  lWK;        cNMMMMMMMMMK,  lWMMMWl    lXMMMMMNKNK;                  //
//          '0MXc.cNMMMWXKKNWMMMMX:   .oXMMMMMMMMMMMMMMMW0:   ;O;          ;OWMMMMMMMX;  dMMMMk.   cNXx0WMMMMNc                   //
//           :XMNc.:0WMMMMMMMMMMNl.     .:lxKWMMMMMMMMNk:.    ..            .;xXMMMMMK, .xMMMO'   ;0k, .oXMMMWk.                  //
//            cNMK, .;kNXkkxxxdl'       ..  .:xKNNNXOo,    .';codkkOOOOkxdl:'. .ckNMMk.  dMWk.   'o:.    ,OWMMWl                  //
//             oWMk.  .kl              ;:.   ....''..    .o0NMMMMMMMMMMMMMMMN0o'  ;ONc   dNo.    ..       .kWMM0'                 //
//             '0MWx.  ,'    ..       lx.   .dd.    ',   oWMMMXdcc:::;;:OWWWMMMXd. .;.   lo           ..   .kWMWx.                //
//              :XMWO;       .:,    'xXl    cNK;    .:c..xMMMMk.       ,00c;o0WMMK;      ..           ,d'   'OMMWk.               //
//               cXMMNd.      'xc .oXMK,   :XMMO'     lx;dWMMMx.      ;Od.   .dWMMK,   .:lddxddddddxxdkNx.   'OWMM0,              //
//                ,0WMM0,      ;OxkWMNo.  ;KMMMWl     .oKXWMMMx.     .:,      '0MMMo  .xMMMMMMMMMMMMMMMMW0o'  .dNMMK;             //
//                 .kWMMk.      lNMMKc   ;KMMMMMK,     .oNMMMMx.              ;XMMMd  .kMMMWNK000KXWMMMMMMMXd' .oNMMk.            //
//                  'OMMNc      cNMX:   '0MMW00WMK;     .xMMMM0'            .cKMMMNc  .xMMWd...  ..,coONMMMMMXc .dWMX;            //
//                   ;XMMX:   .cXMMx.   oWMMWc.xWMXc    .xMMMMWOolcccccclodkXWMMMNd.  .OMMWl           'oKMMMMNl .OMWo            //
//                    oWMMNx'.xWMMX:   '0MMMK, .kMMNc    dMMMMMMMMMMMMMMMMMMMMMWO;    ;XMMMk.            'OWMMM0' ,0MK;           //
//                   'OWMMMMXXWMMWo.   lWMMWo   cNMMk.   :NMMMMWNNNNWWWMMMMMM0l;.     :NMMMK,             ,KMMMN:  .kWK,          //
//                  :0k:dNMMMMMMMk.   '0MMMk.   .dNMX;   ;XMMMMO,.'''',:kNMMMk. .;'   ,KMMMN:             .xMMMMd   .lXx.         //
//                .ld;   oNMMMMMMo   .kWMMW0oooooONMWx.  cWMMMX;        .kMMMWd. .:l, .OMMMK,              cWMMMK;    c0;         //
//               .:,     .OMMMMMWo   lWMMMMMMMMMMMMMMNl  lWMMM0'       .lKNWMMW0;  ,xkxKMMM0'              cWMMMWl     c;         //
//                       .OMMMMMX;  .OMMMMWNNNX00XWMMM0' ;XMMMd.      .o0c'dNMMMX;  .oXMMMMO.      .:,    .kMMMMX:      .         //
//                       .kMMMMWo   :NMMWk;''.....;kWMX; .OMMK,      .ox'   lNMMMx.   lWMMMK,       ,kl. 'kWMMMXc                 //
//                        lWMMM0'  .xMMKc.         .lXX; .OMX:      .::.    .dWMMNc   ;XMMMX;        cKkoKMMMNx'                  //
//                        .kMMMk. .oWMO'             c0: '0Mk.      ..       .lXMMXc  '0MMMNkodddddodONMMMMW0:                    //
//                         lWMMO. :XMK,               cc .kMx.                 'kWMX: .kMMMMMMMMMMMMMMWX0xo;.                     //
//                         cWMMx..xMX:                 . .xMd                   .dWMk. dWWWWWMMMWN0ko:,.                          //
//                         :NMN: ,KK:                     oK,                    .oNK, .,'',,;::,'.                               //
//                         .OWx. lx'                      ::                       ,kl                                            //
//                          lO' .'                        ..                        .'                                            //
//                          ..                                                                                                    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JNKY is ERC721Creator {
    constructor() ERC721Creator("JUNKYARD", "JNKY") {}
}