// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eddie Gangland Limited Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOxoc:;,'''''',:coxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxo:'.   ..',;;;,,'..    .,lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkl;.   .;ldOKXNWMMMWWNXKOxl:'.  .;oOXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc'   ':oOXWMMMMMMMMMMMMMMMMMMN0kdl;.  'l0WMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNx,   ,:ccc;,;cxXMMMMMMMMMMMMWKo;'..';lol;  .:kNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNx,  .:lc,.       .dNMMMMMMMMMXl..        ,od:. .:0WMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWO;  .ckl....         lNMMMMMMW0;...          ;Ok'  'kWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXo.  ;OO;.'.           .dWMMMMMK,.'.  .         'OK:  .xWMMMMMMMMMMMMMMMMMMMMM    //
//    MMWXKKKKKK00OOkdoocoK0;  'xN0,.'. .''         ,KMMWMNc .' .d0o.        ;KXc  .kOcclodxkO00KXNWWMMMMM    //
//    MMO,........       .c'  ;0WX: ''  lNX:        .xMMMMk..,. .xXx.         oWX:  .'         ....',;l0MM    //
//    MMo       ....''.      cXMWd..,.  ,dl.         lWMMNc ..  .;,           ,KM0,                    lWM    //
//    MMd   .lkoclllONd.    :XMMN: ''  .::           :XMM0, '.  lXc           .OMWd.     ;kxollolol.   :NM    //
//    MMx.  .xk.'clo0WO.   '0MMMK; ,'  .c:.          ;KMMO..'.  .'.           .kMMK,    .kMXdccc;oKc   :XM    //
//    MMk.  .xx.cWMMMMX;   oWMMM0' ,'                ,KMMO..,.                .kMMMo    lNMMWNNO',0:   ;XM    //
//    MMO.  .xk.cNMMMMMo  '0MMMM0' ',                ;XMM0'.'.                .OMMMx.  'OMMMMMMO.;0:   ;XM    //
//    MM0'   dKcdWMMMMMO' cNMMMMK, .,.               cNMMN: ..                ,KMMMO.  oWMMMMMMk.l0,   :NM    //
//    MMK,   oWWWMMMMMMWOdKMMMMMX:  '.              .xMMMMx...                ;XMMMXd;oXMMMMMMMN0Xk.   lWM    //
//    MMN:   cNMMMMMMMMMMMMMMMMMWl  .,.             ;KMMMMX: ..               cWMMMMMMMMMMMMMMMMMWo    dMM    //
//    MMWo   'xOOkkkxxOXMMMMMMMMMx.  .;.           .kWMMMMWO....              oMMMMMMMMMMMMMMMMWMX:   .xMM    //
//    MMMx.            lWMMMMMMMMO''l'.''.         :NMMMMMMWo  ..          ...xMMMMMMMWKxoolllccc,.   '0MM    //
//    MMMKc.      .',,:OWMMMMMMMMN:.k0c'.....     .xMMMMMMMMK,  ...       ck;.OMMMMMMMNc              lNMM    //
//    MMMMKc.  ;dOXWWWMMMMMMMMMMMMo cNWKxl::::co; cXMMMMMMMMWd..;;'.. ..ckNO';KMMMMMMMW0l::;,..    .ckNMMM    //
//    MWMK:  .xNMWWWWMMMMMMMMWWMMMk..xWWMWMMWMNo..OMMMMMMMMMMXc :0KOkO0XWMWo :XMMMMMMMMMWMMWWN0x;.  .xWMMM    //
//    MMXc  .xOk0OllKMMMMMMNd,oXMMX; .xNMMMMWK:  oWMMMKxdONMMMO' ;0MMMMMMMO' lWMMMMMMMMMWMNXNMMMNk'  .xWMM    //
//    MMk.  :Xk;...,xXW0ONMNc .xWMWo .'cOXXOl;. :XMMWO'  .lXMMWd. ,dNMMMWO'  dW0dONMWMMMWM0c:dxloKk.  :NMM    //
//    MMd   :NXockOxdd:. ;0MO. cNMMO.,kdclolod,,0MMMO'     lNMMNl.:c:oxxc,,..OX; ;XMNOdxXXd;''.'kN0,  ;XMM    //
//    MMk.  .ckkOkdc'   .xNWNc .dWMNo.oWWWWWK;'OMMMX:      .dWMMX:'k0xoox0x.:X0' oWWO'  'ldkXXxl0No.  lNMM    //
//    MMNo.        .'c; '0WWMo  .lXMXc.dNWWO,,OWMMMx.  ..   ,0MMMK:,kWMMMK;.kNo .OWWWx.   .;ldxxd;   :XMMM    //
//    MMMN0dc:::cox0NWo .kMMMx.   'xNNd;:lc;oXMMMMWl  'kKd. .xMMMMXo,lKW0;.xNd. :XMMWo 'oc'.       'dXMMMM    //
//    MMMWMMMMMMMMMMMX; .xMMMO.   ..,dXXOxkXMMMMMMW0odKMMW0ll0MMMMMW0llocc0Xl.  oWWMK, :NMN0xoccclxXWMMMMM    //
//    MMMMMMMMMMMMMMMO. .xMMM0'   l0o,'lONMMMMMMMMMMMMMMMMMMMMMWWMMMMMWNNXx,   .xMMMx. cNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWl  .kMMM0'   oMMXx'.'lkXWMMMMMMMMMMMMMMMMMMMMMMMMWKd,.c;  .xMMMd  :NMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMK,  '0MMMO.  .dMMMK;   ';:ok0NWMMMMMMMMMMMMMMMWKOo;';o0Wd  .xMMMx. '0MMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMx.  :NMMMd.  'OMMWd.  ,0Kxl;'';:lodxxkkkkxxol:;.  'kNMWMk.  oWMMO.  oWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMN:   dMMMN:   cNMMX:   oWMMMNl  'olc::'   'cloxk;  .xWMMMX;  ;XMMNc  '0MMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMO.  '0MMMk.  .kMMWx.  .kMMMMN:  cWMMMWO'  lWMMMMO.  ,KMMMWd. .kMMWk.  cNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWl   lWMMX;   lNWMX:   :XMMMMX;  lMMMMMX;  ;XMMMMNl   lNMMMX:  :XMMNl  .dWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMM0'  '0MMWo   ;KMMWx.  .dWMMMM0'  dMMMMMWl  .OMMMMM0'  .xWMMMO. .dWMMX;  .kWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMXc  .dWWWk.  ,0MMMK;   ,KMMMMMk. .xMMMMMMd   dMMMMMWo   '0MMMWd. 'OWMMO'  .kWMMMMMMMMMMMM    //
//    MMMMMMMMMMWo.  cNMWO'  ,0WMMWo    oWMMMMMd. .kMMMMWMk.  cNMMMMMK;   :XMMMNl  ,KMMWk.  .xWMMMMMMMMMMM    //
//    MMMMMMMMMWx.  ,KMW0,  ;0MMMMO.   '0MMMMMWl  '0MMMMMM0'  ,KMMMMMWx.  .oWMMMXc  ;KMMWO'  .lNMMMMMMMMMM    //
//    MMMMMMMMWk.  'OMWO,  cXMMMMX:    lWMMMMMN:  ,KMWMMMMX;  .kMMMMMMX:   .kWMWWXl  ,OWMM0;   ;0MMMMMMMMM    //
//    MMMMMMMWk.  'OWWk' .lNMMMMWd.   'OWNXK00x.  'oxxxxxxd'   c0KKXNNWx.   ,0MMWMNo. .dNMMXc   'kWMMMMMMM    //
//    MMMMMMNo.  'OWNo. .dNWNXK0x'    .',..........'''.............''','.    ;k0KXWNx.  ;ONMNo.  .lXMMMMMM    //
//    MMMMWO;   ;0Nk;   'c:;'.....',;:cllllllllloooooooooooooollllllllllllc:;,,,,,,;c;.  .:xXWk'   ,kWMMMM    //
//    MMNO:.  .lXKc...',;:clllcccllc:;,,....                      .....'',;:cllllclllc:;,.. 'oKKc.  .lXMMM    //
//    WO:.   .dKKOoccllc:;,'..      ..'';;:ccllooooooooooollllllccc:::;,'....     ..',:clcc::cONNx'   ,OWM    //
//    0'     .....      ...',:cldxk0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK0Okxdlc:;,'..   ...',;'    ;XW    //
//    Xo,',,;:::cllodxkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKOkxdolc:;,''.'oNM    //
//    MWNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKXWMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GANGLAND is ERC1155Creator {
    constructor() ERC1155Creator() {}
}