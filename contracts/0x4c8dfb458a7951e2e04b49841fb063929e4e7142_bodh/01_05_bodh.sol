// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bodh.io
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMXkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkXMM    //
//    MMo                                                                                                                  oMM    //
//    MMo                                                                                                                  oMM    //
//    MMo                                                                                                                  oMM    //
//    MMo     .l0000OO000000000000000000OO000000000000000000000000O0000000000000000000000000000000000000000000OO0000l.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMMMMMWNK0XWMMMMMMMMMMMMMMMMMMMMW0ocoKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMMMMMO;...lXMMMMMMMMMMMMMMMMMW0:.   .OWMMMMMMMMMMMMMMMMMMMWKKWMMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMMMKl.    .kMMMMMMMMMMMMMMMNkc.      '0MMMMMMMMMMMMMMMMMMWk..xWMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMWO,       cXMMMMMMMMMMMMW0:          .OMMMMMMMMMMMMMMMMXo.  .dNMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMWO'         lXMMMMMMMMMW0l.   ,ll'.    .kWMMMMMMMMMMMMWx.      oNMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMNd.    ..    .kMMMMMMMMNd.   ,xNMMNKd.   .xWMMMMMMMMMWO;        '0MMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMX:     ,Ok'    ;KMMMMMMK:   'kNMMMMMMWO,   ,KMMMMMMMMK:.    .'   .kWMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMX:     :KMWK:    lWMMMM0,  .:0MMMMMMMMMMXo. .oNMMMMMWO'    .cKXd.  ,0MMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMWl     lXMMMMNd.  .OMMWO,  'kN0olclooxkOKNK;  .lXMMMXo.    .lNMMWl   ;KMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMO.   .xNMMMMMMW0:. .xNk.   'c;..        ...     :0NK:     'kNMMMMK:   cXMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMWl   .OWNKxolcccc;.  .:.       .;.     ...        ...      'ollox0NXd. .dWMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMK,   .,;,.        ..      .;c;'......',;:ccldOx,          ...    .'lkc. .kMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMx.     .ll.   .. ,0Xc   .lXWMWNK00KXNWWWMMMMMMMNl    .;:. .'.     ;oc.   '0MMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMK;   ,:. ',.   .;dKWM0' .oNMMMMMMMMWMMMMMMMMMMMMWd   'xNWKxo:..    ,l:.    ,0MMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMNl   ;KWKxddddxkKWMMNKx. 'xkxdoollcclloooooolcllll,   c0XNWMMWX0Oxdoodddo,   ;KMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMO.  ,KMMMMMMWX0Oxoc;'.                                 ..',:ox0XWMMMMMMMMX;   lNMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMNc   cOOOkxdl;..                                                .,cdxkOXWMMd.  .xWMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMX;                 ..';:clloddoooodc.          .odoc:;,'...            .,lo;    .OMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMM0'           .,coddddddddolllc;c00:.           .dXMXdlooooodddoc;..              'OMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMk.       .;lxkxo:'..',;::cc. .:xo.   ;c.   .:'   ;0X;  'lllllcodxkkxo:'.          ;KMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMd     .,oxd:.  .';lddolc:oKo c0:     ,o' .'ld'    ;KK,.xWklooodxolllox00xc'        lWMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMWl    'kk:.   .o0Kkc'.,ol:dKc.kd    ',.      .,cl,  dWx.oNl .:'.:d0X0l..;ldOd.      ;XMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMNo.   ;0Ol;,...cooooooddc;kK,.Oo   .cc.    ...;ll'  :Nk.lNo,cxxoolooc:'';:oKk.    .l0WMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMWNKo.  .,cokOOdc:,.',:loooxo..xd.    .ox' .,ok:.    lXl 'ddoc:;,',:ldkOOxoc;.   .:OWMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMWXkl;.   .,coxkxddol:,'....d0,    :Ox.   'dd'  ,d0o..':cldkkxdxdlc;'.    .,cxKWMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMWKd;.      ..';:looooookXKc              'kNWKxodxxolc;'.        .'cx0NMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMWKOdl:,'.         ....'.              ':;,'..          ..,:lox0NMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMMMMMMMWWKOxoolcc:;,'...                     ..',;:ldkO00XWMMMMMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OkxdddddddddddddddkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMNkldodXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOxkkkOXWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMx;c,  ;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo'c;  .:o:;cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMd;0d.  oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:;X0' .dXc  ,0MMMMMMMMMMMMNkolccdKMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMd,Ok.  lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc,0X;  cNO. .oWMMMMMMMMMMNo:xO:  ,0MMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMWl.xk.  cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx;kNc  ,KK,  :NMMMMMMMMMXocKMMNd. 'xNMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMK;.xO.  :NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO:kWo. .ONc  ,KMMMMMMMW0coXNdoKWO, .cXMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMX; oK,  .oxxkOkxxxoddodxxxxdddxxxdddddooxxxl.dWOc. dWx. .d0OOO00OdckN0;  'kNXl. ,odddddddddodONMMMx.     oMM    //
//    MMo     .xMMWc lXkloooooooolldkkxddooooooloodddddddooooolkWXk; ;XXl;:looooo,.:XMW0xddokNMWKxodddddxxkkx;  :XMMx.     oMM    //
//    MMo     .xMMWl :NMMW0ddddxxONMMMM0dddddddxKMMMNkloodxxkXMMMNK: .OMN0OOkxkXWo 'looooooddxx0WMNkoolllxXMX:  :XMMx.     oMM    //
//    MMo     .xMMM0,;XK0NO,   ..lNXddXKc.  .l,,0Xk0NO;   ,';0WXNWNl  oW0, .'.'OX:  ,dkx;.,.  .:oKWx.   'xXk, .lXMMMx.     oMM    //
//    MMo     .xMMM0,;Kd.:0Xd. .oNK;  ;ONk' .'c0K: .lXNd. .cKNo;OWWd  ,KX:  ..oNx.  ,ood;cXd. .dxcOWO' ;0Xl. ;OWMMMMx.     oMM    //
//    MMo     .xMMMX:;Xd  .dXOlkNO,  ;ocdN0;.;KK;  'cckNOcoXXc .xMMO. .kWd   ,KX; .ox;.  ;Kk. .dWk:kW0xKX:  :KMMMMMMx.     oMM    //
//    MMo     .xMMMMd,0x.  .lKMNx.  ;0MKllXX0XK;  'OW0coXWW0,  .;0WO'  lKo. .dWd..dWMNx' ,00'  oWWx;kWMK;  :XMMMMMMMx.     oMM    //
//    MMo     .xMMMMKlcc,.:xdclc. .dXMMMNdcON0;  'kWMMKlcxd' .ckdldl:;clol::,co. 'OWNNKl .ll. .xMMNc,kk, .:KMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMWXNNXWMWKkOOOKWMMMMMWOool,,lKWMMMMNOodookNMMWWWWWWMMMMMKdooocldolcc:clodd0WMMMKdoollkNMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo     .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.     oMM    //
//    MMo      l0O0OO000000000000000000000000000000000000000000000000000000000000000000000000000000000O00000000000O0l      oMM    //
//    MMo                                                                                                                  oMM    //
//    MMo                                                                                                                  oMM    //
//    MMo                                                                                                                  oMM    //
//    MMXkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkXMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract bodh is ERC721Creator {
    constructor() ERC721Creator("bodh.io", "bodh") {}
}