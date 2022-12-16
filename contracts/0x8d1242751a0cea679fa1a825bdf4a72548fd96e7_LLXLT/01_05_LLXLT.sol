// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CDB: LOST LEGENDS by loosetooth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//        'kWx.   .oN0,    :KNl    'kWx.   .dNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNd.   .dWO,    :XXc    'ONd.   .dWO,    cXNNNNNNNNNNNN    //
//      cOx:'.  ;kOl''. .dOo,'.  lOx:'.  ,kOl''''''''''''''''''''''''''''''''''''''''''''''''''''''''''ckO:  .';dOl. .',oOx'  .'ckO;  .';xOl. .'''''''''''''    //
//    lllo:. .:llol'  ;lllo;  'cllo:. .:llol'  ;llllllllllllllllllllllllllllllllllllllllllllllllllll;. .collc. .:olll,  ,olll;. .collc. .:olllllllllllllllll    //
//    0O,  ..:k0c  ..,d0d. ..'l0k,  ..:k0c  ..,d0000000000000000000000000000000000000000000000000000x;..  :0Oc..  'k0o'.. .o0x;..  :0Oc..  'k000000000000000    //
//    ..  .xNx'.   lX0;..  ;0Xl..  .xNx'.   lX0;....................................................,OXo.  ..dNk'  ..cKK:  ..,OXo.  ..dXk.  ................    //
//      :xdc:'  ,dxl:,. .lxo:;.  :xdc:'  ,ddl:,. .lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo. .,:cdd,  ':coxc. .;:oxo. .,:cdd,  ':coxxxxxxxxxxxxxxxxxx    //
//    ;:oxl. .,;lxd,  ':cdx:  .;:oxl. .,:lxd,  ':cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc:,  'dxl:;. .lxo:;.  ;xdc:,  'dxl:;. .lxxxxxxxxxxxxxxxxxx    //
//    XK;  ..;0Xl   .'xNk.  ..lX0;  ..;0Xl   ..xNx.  ..........................................  .xNk'.   cXK:..  ,0Xo..  .dNk'..  cXK:.....................    //
//    ... .d0d,..  c0k:..  ,k0l'.. .d0d,..  c0k:..  ,k0000000000000000000000000000000000000000O;  ..;x0l  ..,d0x.  .'cOO;  ..:k0l  ..,d000000000000000000000    //
//      ,olll;. 'llll:. .:llll'  ;llll;  'llll:. .:llllllllllllllllllllllllllllllllllllllllllllllc. .:llll'  ,lllo;. .clllc. .:llll'  ,lllllllllllllllllllll    //
//    ',o0d.  .'cOk;  .':xOl  .',o0d. ..'cOk;  .':x0l  .''''''''''''''''''''''''''''''''''''.  cOk:'.  ,kOl''. .o0d;'.  cOk:'.  ,kOl''''''''''''''''''''''''    //
//    NK:    ,0No.   .xNk'    cXK:    ,0No.   .xNk'    lXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNo    .xNk.   .lXK;    ;0No    .xNk.   .lXNNNNNNNNNNNNNNNNNNNNNNN    //
//    ;,. .lko:;.  :kxc;'  'dkl;,. .lko:;.  :kxc;'  'dkl;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;lxx,  ';cdk:  .;:oko. .,;lxx,  ';cdkc  .;;;;;;;;;;;;;;;;;;;;;;;;    //
//      ':cod:. .::ldl. .,:ldd,  ':cod:. .::ldl. .,:ldd,  '::::::::::::::::::::::::::::::,  'odl:;. .cdlc:.  :doc:,  'odl:;. .ldoc::::::::::::::::::::::::::    //
//    ..dXk'  ..cKK:  ..;kXo.  ..dXk'  ..cK0:  ..;OXo.  ..dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx'..  lXO:..  ;0Kl..  .xXx'..  lXO;..  ;0XXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KOc..  'kKo'.. .oKx;..  :0Oc..  'kKo'.. .oKx,..  :0Oc..............................:OKc  ..,xKd.  ..l0O,  ..:OKl  ..,dKd.  ...........................    //
//    MX: .:oocc'  ,oolc;. .lolc:. .:olcc'  ;oolc;. .lolc:. .:ooooooooooooooooooooooooc. .;cloo'  ,ccoo;  'ccloc. .:cloo'  ,ccooooooooooooooooooooooooooo;      //
//    MN: .OMk. .',oOd'  ',ckk;  .,:dOl. .',oOd'  ',ckk;  .,:dOOOOOOOOOOOOOOOOOOOOOOOOx:,.  ,kkl,'. .dOo;,.  cOx:,.  ,kkl,'. .dOOOOOOOOOOOOOOOOOOOOOOO0NMx.     //
//    MN: .OMk. cXNc    'ONd.   .dNO'    :XX:    'ONd.   .dNO'  ....................  .kNx.   .oN0,    ;KXl    .kNx.   .dWK;  ......................  ,0Mx.     //
//    MN: .OMk. cNNc .lOd:,.  ;kkc,'  'dOo,'. .lOd:,.  ;kkc,'  'dOOOOOOOOOOOOOOOOOOx,  .,cxO:  .,;dOo. .',lkx'  .,cxO:  dMWKOOOOOOOOOOOOOOOOOOOOOOOd' '0Mx.     //
//    MN: .OMk. cNNc .kMO. .:clol. .;cloo,  'cclo:. .:clol. .;cloooooooooooooooooooolc;. .lolc:. .:oocc,  ,oolc;. ,KMd  ;ooooooooooooooooooooooodKMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWl  ..,xKo. ..'oKk'  ..cO0:  ..;xKo.  ..............   lKk;..  ;00c..  .xKd'.. .xM0' ,KMx'........................  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWl .oXO;..  ;0Kc..  'kXd..  .oXk;..  :KXXXXXXXXXXXKc   ..,kXd.  ..oXO'  ..:0Kc .xM0' ;KMNXXXXXXXXXXXXXXXXXXXXXXXXl  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWl .xM0' .ldlc:. .:doc:'  ,ddl:;. .ldlc::::::::::::lddo' .,:cod;  ':codc. :XWl .xM0' .;:::::::::::::::::::::::dNWd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd    .kMO. .,;lkd'  ';cxk:             ;xxxc;,. .oko;,. .kMO. :XWl .xMXl;;;;;;;;;;;;;;;;;;;;;;;'. ,KWd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd    .xWk. :XWl    'kNx.                  .dNO,    cNNc .kMO. :XWl .dNNNNNNNNNNNNNNNNNNNNNNNNNW0' ,KWo  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  cOk:'.  ;XWl  l0x:'.                    .';x0o. cNNc .kMO. :XWl  .''''''''''''''''''''''';OM0' ,KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, .:llll' .xMXxl;          .:lllllllc. .OMk. cNNc .kMO. :XWOlllllllllllllllllllllllc' .xM0' ,KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. ..,OMWK0d,..     ..cKMNK0000Oc.:0Mk. cNNc .kMO. ,k00000000000000000000000XWWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. cXNWMK;.;0Xl    .xNNWMk......dXNWMk. cNNc .kMO.  ........................cNWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. oWMMM0' ,KMKxd, .kMMMMx.    .xMMMMk. cNNc .kMO. 'dxxxxxxxxxxxxxxxxxxxxl. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. ;dkXMXo;dNMKkd, .cxONM0c;::::oxONMk. cNNc .kMKl;ldxxxxxxxxxxxxxxxxxkXMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, 'ONd..  .xMWNXNWMx..     'OXXXXXXX0; .OMk. cNNc .kMWNXo.  .............  .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK,  ..cO0: .xMKc.cXMNKO;     .......... .OMk. cNNc .kM0:..  :000000000000O; .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  ,lllo:. :XWl .xM0' .:lllc.                .OMk. cNNc  ;l;. .colllllllllllkWNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' 'xOo,'. .kMO. :XWl .xMKc'''''''''''''''.        .OMk. cNWd'..  .'ckO:  .''''.  cNNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0'    cXX: .kMO. :XWl .xMWNNNNNNNNNNNNNNNNd.       .OMk. cNWNN0, 'ONd.   .dNNNNx. cNNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWl  .;:dkl. cNNc .kMO. :XWl .xMXl;;;;;;;;;;;;;;;.        .OMk. .,;;;:dkd:;.  ;xxc,cKMk. cNNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. 'odl:;. .OMk. cNNc .kMO. :XWl .xM0'            .,:'  .::;. .OMKl::::::codc. .;:ldo' .OMk. cNNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .dXk,..  lWX: .OMk. cNNc .kMO. :XWl .xM0'            '0Mx. oNWN: .OMWXXXXXXXO:....:0Kc  ..,kXd. cNNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc  ..;kKo. lWX: .OMk. cNNc .kMO. :XWl .xM0'            '0Mx. oNWN: .OMO,......,xKKKKd'.. .oKk;..  cNNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. .:cloc. '0Mx. lWX: .OMk. cNNc .kMO. :XWl .xM0'            '0Mx. lNWN: .;c,  'loooxXMXdc,  ,odKM0' .colc:. .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .oOd;,.  oMK, '0Mx. lWX: .OMk. cNNc .kMO. :XWl .xM0'          .,:xOc  :kkkc,'     ,kOOOOOOd:,.  ;kONM0' ;KMd  .,;dOo. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    WX:    ;KWo  dMK; '0Mx. lWX: .OMk. cNNc .kMO. :XWl .dW0,         .kWO'.    ...xW0'            'ONd.   .xW0' ,KMd  oWK;    :XNl .xM0' ;KMd  dMK, '0Mx.     //
//    ,;oOd. ,KMd  dMK; '0Mx. lWX: .OMk. cNNc .kMO. :XWl  .,:dOl.      .kMN0Oc  ;kkOXM0'            .',ckOOOkc,'  ,KMd  dMK, .dOo;,. .xM0' ;KMd  dMK, '0Mx.     //
//     .xM0' ,KMd  dMK; '0Mx. lWX: .OMk. cNNc .kMO. .lolc:. .OMk.      .:okNM0lcOWWWOoc.               :XW0dl. .;cloo;  dMK, '0Mx. 'ccloc. ;KWo  dMK, '0Mx.     //
//     .xM0' ,KMd  dMK; '0Mx. lWX: .OMk. cNNc .oKx,..  lWX: .xKx,..       .xKKKKKKKO,                  :XWl  ..,xKo. ...oKk' '0Mx. oWX:  ..:OKc  dMK, '0Mx.     //
//     .xM0' ,KMd  dMK, '0Mx. lWX: .OMk. cNNc  ..;kXo. lWX:  ..;OKl        .........                   :XWo .oXk;..  :0Kc..  '0Mx. lWX: .xXx'..  dMK, '0Mx.     //
//     .xM0' ,KMd  dMK, '0Mx. lWX: .OMk. .::ldl. '0Mx. .:codl. ,KWo                                 .cdoc:. .xM0' .ldl::. .:doc:'  lWX: .OMk. 'odl:;. '0Mx.     //
//     .xM0' ,KMd  dMK, '0Mx. lWX: .lko:;.  dMK, .oko:,. .xM0' .dko;;;;;;;;;;;;;;;;,.       .,;;;;;;cdkc  .,;oko. ,KMd  .;:okl. .,;lkd' .OMk. cNNc  ';cdkc      //
//     .xM0' ,KMd  dMK, '0Mx. cXK:    ,KWd  dMK,    :XWl .dNO,    cNWNNNWWWNNNNNNXNK:      .cXNNNNXNk.   .lXK;    ;0No  dWK;    :KXc    'kNx. cNNc .kMO.        //
//     .xM0' ,KMd  dMK, '0Mx. .',o0d. ,KMd  dMK,    ;XWl  .';x0o. cNWd':0M0:''''''',o0d. 'x0o,''''''.  ,kOl,'. .o0d;'.  dMK, .d0o,'.  l0x:'.  cNNc .kMO. ,kO    //
//     .xM0' ,KMd  oWK, .:ollc' .xM0' ,KMd  dMK, .:llll'  ,lllo;. cNNc .kMO.       .xM0' ,KMd  ,llllllllll'  ,lllo;. .clloc. '0Mx. 'cllo:. .:llol' .kMO. :NM    //
//     .xM0' ,KMd  c0k:..  :XWo .xM0' ,KMd  dMK, '0Mx. ..,d0x.  .'dWNc .kMO.    ...,kM0' ,KMd  dMWK0000l  ..,d0x.  ..cOO;  ..:x0l. lWX:  ..:k0c  ..,d0d. :NM    //
//     .xM0' ,KMd   ..xNk. :XWo .xM0' ,KMd  dMK, '0Mx. cXK:..  ,0NNMNc .kMO.    cKXNWM0' ,KMd  dMX:....   cXK:..  ,OXo..  .dNk'..  lWX: .kNx..   lX0;..  :NM    //
//     .xM0' .,:lxd, .kMO. :XWl .xM0' ,KMd  dMK; '0Mx. lWX: .lxo::::;. .kMO. 'dxl:::::,. ,KMd  dMK, .lxxxxl:;. .cxo:;.  ;xdc:,  'dxl:;. .OMk. ,dxl:,. .lxo::    //
//      :xdc:'  cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. lWX: .lxo::::::::oxl. 'dxl::::::::cdx;  oWK, '0MXkd;  ':coxc. .;:oxo. .,:ldd,  ':coxc. cNNc  ':cdx:      //
//    ..  .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. cXK:..  ,0NXXXXXO'  ..   cKXXXXXXXx.  ..oX0, '0Mx.  ..dNO'  ..cKK:  ..,ONo.  ..dNk.  ..cKK: .kMO.  ..    //
//    0k, .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. ..,d0x.  ........  .x0l  ..........  ;OOc'.  '0Mx. :0Oc..  'k0o'.. .o0x;..  :0Oc..  'k0o'.. .kMO. ,k0    //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, .:llll'  ,llloooooooooooolllllooooooooooooollc. .;olll,  lWX: .:olll,  ,olll;. .collc. .:olll'  ,olll;. :NM    //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  cOk:'.  ,kOl'.. .o0000000000O0o. ,k0000000000000c  .';d0o. .''lOk, .OMk. .',o0x'  .'ckO;  .';xOl. .',oOx'  .'ckO    //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KWd.   .xNk.   .lXK;  ..............   ..............   lN0;    ;KXl.   .OMk. :XXc    'ONd.   .dNO,    :XXc    'ONd.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' .,;lxx,  ';cdkc  .,;okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxl;,. .oko;,.  ckdc;'  cNNc .lkd:;.  ;xxc;'. .dko;,. .lkd:;.      //
//    MN: .OMk. cNNc .kMO. :XWl  :doc:,  'odl:;. .cdoc:.  :dddddddddddddddddddddddddddddddddddo'  ,:cod;  .:codl. .;:ldo' .kMO. .;:ldo. .,:cod;  ':codc. .;:    //
//    MN: .OMk. cNNc .kMO. ;0Kl..  .xXx'..  lXO:..  ,0Kl.........................................'xXx.  ..lK0,  ..:OXl  ..'xXx. :XWl  ..,kXd.  ..oXO'  ..c0X    //
//    MN: .OMk. cNNc .kMO.  ..lKO,  ..:OKl  ..,dKd.  ..lKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO:..  ,OKl..  .dKd,..  lKO:..  :XWl .oKk;..  ;00c..  .xKd'.    //
//    MN: .OMk. cNNc  ,ccoo;  'ccloc. .:cloo'  ,ccoo;  'ccccccccccccccccccccccccccccccccccccccccc:. .colcc'  ;oocc,  'oolc;. .colcc' .xM0' .lolc:. .:oocc,      //
//    MN: .OMk. ,kkl,'. .oOo;,.  cOx:,.  ,kkl,'. .dOo;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:xOc  .,;oOd. .',lkk,  .,:xOc  .,;oOo. ,KWo  .,;dOo. .',    //
//    MN: .kWk.   .oN0,    ;KNl    .kNx.   .oN0,    ;KNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNk.    lXK;    ,0No.   .xNk.    lXK;    ;KWo  oWK,    :KN    //
//    MN:  .,:xO:  .,;dOo. .',lkx'  .,cxO:  .,;dOo. .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.  'xkl,'. .oOd;,.  :Oxc,.  'xkl,'. .oOd;,.  dMK, .dOo;,    //
//    oolc;. .colcc. .:oocc,  ,oolc;. .colc:. .;oocccccccccccccccccccccccccccccccccccccccccccccccccccccloo,  ,ccoo:. .:cloc. .;cloo,  ,ccoo:. .:cloc. '0Mx.     //
//      lKk;..  ;00c..  .xKd'.. .lKk;..  ;00c..  .xKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKl  ..'dKx.  ..c00;  ..;kKl. ..'dKx.  ..c00;  ..;kKl.     //
//      ..,kXd.  ..oXO'  ..:0Kc  ..,kXd.  ..oXO,  ......................................................  cK0:..  ,OXo..  .dXk,..  cK0:..  'OXo..  .dXk,..      //
//    do' .,:cdd;  ':codc. .;:ldo' .,:cdd;  ':coddddddddddddddddddddddddddddddddddddddddddddddddddddddddddl:;. .cdoc:'  ;ddc:,. 'odl:;. .cdoc:'  ;ddc:,. 'od    //
//    MN:    ,KMd    .kMO.    lWX:    ,KMd    .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl    .OMk.    dMK,    :XWl    .OMk.    dMK,    :NM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LLXLT is ERC721Creator {
    constructor() ERC721Creator("CDB: LOST LEGENDS by loosetooth", "LLXLT") {}
}