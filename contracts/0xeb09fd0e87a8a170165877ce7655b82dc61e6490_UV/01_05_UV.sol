// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Uncanny Valley
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    .;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,.       //
//      lWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMK,     //
//      lWO;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,oNK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd      .;lll'             'lll;.                                                                                                             ;XK,     //
//      lWd      .OMMMo             dMMMO.                                                                                                             ;XK,     //
//      lWd      .oOOOo,''.     .'',kMMMO.       .''''.     .'''''''.     .';:;,.      .''''''.   ..        .. .'',''''.       .''.                    ;XK,     //
//      lWd           cXNNK,   ,KWNNWMMMO.     .:oxdddl;.  .OKxddddxdc' .ckdlcldO0d. .'cdxdddxo:. lX;      ;Kl.xKdoooodkx'   .:oxdl;.                  ;XK,     //
//      lWd           :XNN0;   ;0NNNWMMMO.   .:ol.    .ol:..Ok.     .kO.:Xd     ,dx: ,Kd      .c: oN:      ;Xo.kk.     ;Kd..:oc.  'ol;.                ;XK,     //
//      lWd            .'',dOOOd,'',kMMMO.   lNc        lN:'00c::::::oc..x0dc;,..    ,Kd          oN:      ;Xo.kO,....'o0: dK,      oX:                ;XK,     //
//      lWd               .xMMMx.   dMMMO.   lNc        lN:'0Xdooooool,   .;coddxkd, ,Kd          oN:      ;Xo.kXdloookKo. dXo,;,;,;kX;                ;XK,     //
//      lWd           .looolccclooodKMMMO.   ;Oc.      .lO,.Ok.     .kk.,:.     ':kK,,Kd       .. lNc      :Nl.kO.    .dX: dNOddddddKX;                ;XK,     //
//      lWd           cNMMX;   ;XMMMMMMMO.    .:o:'''':d;. '0O;''''';dl.:0x'.  .,cOO'.do,''''';o: '0O;.  .,O0,.kO.     ,Ko oK,      oX: ..             ;XK,     //
//      lWd       ';,,lxxko.   .dkxkXMMMO.      .cxxxx:.   .lkxxxxxxo.   'ldolloodc.   'dxxxdxl.   .cdollodl. .ll.     .oc.;d.      ;d'.cc.            ;XK,     //
//      lWd      .OWWWo             dMMMO.                                                                                                             ;XK,     //
//      lWd      .xXXXl             lXXXx.                                                                                                             ;XK,     //
//      lWd       .....             .....                                                                                                              ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd           ,:.        ;:.   ,ccc;.    .:;.     .;lodol:.          ,cccc,       .;ccc,     .c,   .;ccc'     'c'  .::.        .;c'            ;XK,     //
//      lWd          .ON:       .ON:  .xWO0Nc    ;X0'   .cKKxlcld0Xd.       :X0o0MK;      '0XkKK,    lWx.  ,KXkK0'    oMx. .oNO.       oNO'            ;XK,     //
//      lWd          .ON:       .ON:  .xWl:XO.   ;X0'   lN0,     .dNO.     .kNc lXNx.     '0X:lNx.   lWx.  ,KK:oWd    oMx.  .dNk.     lN0'             ;XK,     //
//      lWd          .ON:       .ON:  .xWl.dNo   ;X0'  '0N:       .k0;     lNk. .cONc     '0X;.ON:   lWx.  ,KK,'0X;   oMx.   .dNx.   cX0,              ;XK,     //
//      lWd          .ON:       .ON:  .xWl '0K;  ;X0'  ,KK,        ..     ,0X;    :N0'    '0X; :XO.  lWx.  ,KK, cNk.  oMx.    .dNx. cX0,               ;XK,     //
//      lWd          .ON:       .ON:  .xWl  lNx. ;X0'  ,KK,              .dWd.    .xWo    '0X; .dNo  lWx.  ,KK, .xNl  oMx.     .xNxoXK,                ;XK,     //
//      lWd          .ON:       .ON:  .xWl  .kNc ;X0'  ,KK,        .,.   :XNo,,,,,,dNX;   '0X;  ,0K, lWx.  ,KK,  ;K0' oMx.      .dNW0,                 ;XK,     //
//      lWd          .kWl       '0X;  .xWl   ;X0';X0'  .ONc       '0X:  .OWKkOOOOOOOKWk.  '0X;   lNx.lWx.  ,KK,   oNd.oMx.       .ON:                  ;XK,     //
//      lWd           cNK;     .xNx.  .xWl    oWocX0'   cNK:.    'kNx.  lWO.        '0Nc  '0X;   .kNclWx.  ,KK,   .OXcoMx.       .ON:                  ;XK,     //
//      lWd            ;kKOxddkK0o.   .xWl    '0KOX0'    ;kKOxddkK0l.  ,KX:          cN0' '0X;    :XKOWx.  ,KK,    cN00Wd.       .ON:                  ;XK,     //
//      lWd              .;:cc:,.      .,.     .,,,'       .;ccc:'.    .,'            ',.  ',.     ',,,.    ''      ',,,.         ',.                  ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                 ..           .        ....         ..               ...               ...........     .           ..                       ;XK,     //
//      lWd                'kO,        .d0:      ;0xx0c       .xO,             .xKk'             .x0OOOOOOOOOc   ;Ok'        l0o.                      ;XK,     //
//      lWd                .dWx.       cN0'     .ONc;KK,      '0X;             ,KMK,             '0No.........    lNO'      lN0'                       ;XK,     //
//      lWd                 ,KX:      .OWl      oNx. oWx.     '0X;             ,KMK,             '0X;             .oNO.    cX0,                        ;XK,     //
//      lWd                  oWk.     lNO.     ,KK;  .ONc     '0X;             ,KMK,             '0X;              .oNk.  :X0,                         ;XK,     //
//      lWd                  .ONc    '0Nc     .xWo    cNO.    '0X;             ,KMK,             '0WOdddddddd,      .dNx.:XK;                          ;XK,     //
//      lWd                   cNO.   oWx.     cN0'    .kWo    '0X;             ,KMK,             '0Nxcccccccc.       .dNKXK;                           ;XK,     //
//      lWd                   .kWl  ,KX;     .OMXkkkkkkKMK;   '0X;             ,KMK,             '0X;                 .dWK;                            ;XK,     //
//      lWd                    :X0'.dWd      oWOc;::::::kWx.  '0X;             ,KMK,             '0X;                  cNO.                            ;XK,     //
//      lWd                    .xWdcKK,     ;KX;        '0Nc  '0Nx::::::::;.   ,KMNd::::::::;.   '0Nx::::::::'         cNk.                            ;XK,     //
//      lWd                     'ddox:      ;xc          ;xc. .lxxxxxxxxxxd'   .okxxxxxxxxxxd'   .lxxxxxxxxxxc.        'xc.                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWd                                                                                                                                            ;XK,     //
//      lWXkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0WK,     //
//      ;O00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000x.     //
//        ............................................................................................................................................. .       //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UV is ERC721Creator {
    constructor() ERC721Creator("Uncanny Valley", "UV") {}
}