// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Secrets OE
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                  //
//    MMMMMMMMMMMNk,.':kWMMMMMMMMMMMMMMMMMNk;..cXMMMMMMMMMMMMMMMMMMMW0c..;0WMMMMWO;..,cok0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:..cKMMN0l..';:cllooddddxkOOOkxdlccclkNMMMMMMMMMWk,..:kNMMMMMMMMMMMMMMMMMMMMMMMWXOoc,'.....,:lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo'.'x    //
//    MMMMMMMMMWOc.    oNMMMMMMMMMMMMMMWKd;.   .kMMMMMMMMMMMMMMMMMNk:.    lNMMMMXc      ..';cox0NWMMMMMMMMMMMMMMMMMMMMWXd;.   .xWMk:.               .....       .xWMMMMMMW0c.    lNMMMMMMMMMMMMMMMMMMMMMNx:'.             .,lkXWMMMMMMMMMMMMMMMMMMMMMMMNOl'    ;    //
//    MMMMMMMNO:.     :KMMMMMMMMMMMMMW0l.     ,xNMMMMMMMMMMMMMMMXd,     .lXMMMMMK,             .':xKWMMMMMMMMMMMMMMMWKl.     'xNMWx;.                    ..... .'kWMMMMNO:.     ;0MMMMMMMMMMMMMMMMMMWNOl'                     'dXMMMMMMMMMMMMMMMMMMMMNk;.    .:0    //
//    MMMMMWO:.    .cxXMMMMMMMMMMMMW0l.     'dXMMMMMMMMMMMMMMMXd'     .l0WMMMMMMX:    .:lc:,..     .lKWMMMMMMMMMMMWKl.     'dXMMMMWXKOOO0OOOkkc.    .cxkO0KK0000XWMMMW0:.    .cxXMMMMMMMMMMMMMMMMMMKo'     ..,:clloxxxdo:.      ;0MMMMMMMMMMMMMMMMMNk;     .:ONM    //
//    MMMWKl.    .lKMMMMMMMMMMMMMW0l.    .;xXMMMMMMMMMMMMMMMXd'     ,dKWMMMMMMMMWl    cNMMMWX0d;.    'kWMMMMMMMMWKl.     ,xXMMMMMMMMMMMMMMMMMMx.    ,KMMMMMMMMMMMMMMKl.    .cKWMMMMMMMMMMMMMMMMMMMK:     ,xKNWMMMMMMMMMMWXk;     ;KMMMMMMMMMMMMMMNk;     .cOWMMM    //
//    MWXd'     ;OWMMMMMMMMMMMMN0l.    .:ONMMMMMMMMMMMMMMWKd'     ;kNMMMMMMMMMMMNl    lWMMMMMMMNx'    '0MMMMMMW0l.    .;kNMMMMMMMMMMMMMMMMMMMMK;    .OMMMMMMMMMMMMXd'     ,kWMMMMMMMMMMMMMMMMMMMMNl     cKWMMMMMMMMMMMMMMMMNk'    lNMMMMMMMMMMWXk;.    .lKWMMMMM    //
//    WO,     'dNMMMMMMMMMMMWKd,.    .;OWMMMMMMMMMMMMMMNk:.     'xNMMMMMMMMMMMMMX:    lNMMWNKkl;.    'dXMMMWXd;.     ;kNMMMMMMMMMMMMMMMMMMMMMMWo    .dWMMMMMMMMMMO,     .dXMMMMMMMMMMMMMMMMMMMMMWk.   .oNMMMMMMMMMMMMMMMMMMMMO'   ,KMMMMMMMMWOl'     .lKWMMMMMMM    //
//    Wx.    .oXMMMMMMMMMMMWk'      ,kNMWWNXXKNWMMMMMMK:      .oXMMMMMMMMMMMMMMMX;    ;kxo:'.     .;dXWMMMWO,      ,xNMWWNNXKXWMMMMMMMMMMMMMMMWd     oWMMMMMMMMMMk.    .lXMMMMMMMMMMMMMMMMMMMMMMX:    cNMMMMMMMMMMMMMMMMMMMMMk.   .OMMMMMMMNo.     .c0WMWWNXXXNM    //
//    MWO:.    ,dXMMMMMMMWKl.     .;ool:;,'...,kWMMMNx'     'l0WMMMMMMMMMMMMMMMMX:          ..;cdkKWMMMMWKo.     .,odlc;,'...'xWMMMMMMMMMMMMMMWl    .kMMMMMMMMMMMWO:.    'oKWMMMMMMMMMMMMMMMMMMMO.   .dWMMMMMMMMMMMMMMMMMMMMX:    .kMMMMMWO;      .:doc:;,'...:K    //
//    MMMNOl.    'dXMMMMKo.                   .dWMNx,     .dXMMMMMMMMMMMMMMMMMMMWo          lKWMMMMMMMMXo.                   .oNMMMMMMMMMMMMMMNc    '0MMMMMMMMMMMMMW0l'    .oXMMMMMMMMMMMMMMMMMMx.    oWMMMMMMMMMMMMMMMMMMMMK,    .dWMMWO:.                   'O    //
//    MMMMMWXx:.   ,kWMWO;           ...';:cox0NMMXl.     .xWMMMMMMMMMMMMMMMMMMMX:    ...   .oXMMMMMMMM0;           ...',:coxONMMMMMMMMMMMMMMMK;    .OMMMMMMMMMMMMMMMWXk:.   'xNMMMMMMMMMMMMMMMMx.   .dWMMMMMMMMMMMMMMMMMMMMWo     oWMMNd.          ...',;:lokKW    //
//    MMMMMMMMWKc   .lXMMXd,      .lOKXNNWWMMMMMMMMWO:.    .:kNMMMMMMMMMMMMMMMMM0'    :KOc.   ;OWMMMMMMMNx,      .lkKXXNWWMMMMMMMMMMMMMMMMMMMM0'     dWMMMMMMMMMMMMMMMMMWKc.  .lXMMMMMMMMMMMMMMMO.    lNMMMMMMMMMMMMMMMMMMMMNl    .dWMMMW0l.      ,d0KXNWWMMMMMM    //
//    MMMMMMMMMNo.   .OMMMMXx,     .;dKWMMMMMMMMMMMMMWOc.     'lONMMMMMMMMMMMMMMX;    :NMWO,   .oXMMMMMMMMXx;.    .;dKWMMMMMMMMMMMMMMMMMMMMMMMK,     cNMMMMMMMMMMMMMMMMMMNd.   .kMMMMMMMMMMMMMMMX:    .oNMMMMMMMMMMMMMMMMMMWd.    :XMMMMMMW0l.     .ckXMMMMMMMMM    //
//    MMMMMMWXk;.  .;kWMMMMMMNk:.     .ckNMMMMMMMMMMMMMW0l.     .,dKWMMMMMMMMMMMWo    :XMMMXo.   ,kNMMMMMMMMNk:.     .:kNMMMMMMMMMMMMMMMMMMMMMK;     lNMMMMMMMMMMMMMMMWXk;.  .;kNMMMMMMMMMMMMMMMMO.    .xWMMMMMMMMMMMMMMMWKc.    :KMMMMMMMMMWKd,      'o0WMMMMMM    //
//    MMMN0xc.   .l0NMMMMMMMMMMW0l'      ,dKWMMMMMMMMMMMMWXd;.     .ckNMMMMMMMMMWx.   ;XMMMMWKl.  .:OWMMMMMMMMW0o'      'oKWMMMMMMMMMMMMMMMMMMK,    .xMMMMMMMMMMMMMNKxc'   .lONMMMMMMMMMMMMMMMMMMWk.    .dXWMMMMMMMMMMXkdc.    .oXMMMMMMMMMMMMMNk:.     .:kXWMMM    //
//    W0o,.    .oKWMMMMMMMMMMMMMMMXk:.     .:xXWMMMMMMMMMMMMNOl'      'o0NMMMMMM0,    ,KMMMMMMWd.   .:ONMMMMMMMMMNkc.     .:xKWMMMMMMMMMMMMMMM0'    .OMMMMMMMMMMWKo,.    .lKWMMMMMMMMMMMMMMMMMMMMMWO;     .:ldxkkkkxoc.      .:OWMMMMMMMMMMMMMMMMWKd,.     'lONM    //
//    o.     ,o0WMMMMMMMMMMMMMMMMMMMWKx;.     .cOWMMMMMMMMMMMMMNkc.     .;xXMMMWo     ,KMMMMMMMNd.    .;kNMMMMMMMMMWKx:.     .:OWMMMMMMMMMMMMM0'    ;KMMMMMMMMMNd.     ,o0WMMMMMMMMMMMMMMMMMMMMMMMMMXx;.                   .cOWMMMMMMMMMMMMMMMMMMMMMNOo,.     'o    //
//        .ckNMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.   'kWMMMMMMMMMMMMMMMWXkc.   .lXMMMWl     ,KMMMMMMMMWKo.    ,0MMMMMMMMMMMMWKx;.   .xWMMMMMMMMMMMMMK,   .dWMMMMMMMMMx.   .:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc,.           .,ckXWMMMMMMMMMMMMMMMMMMMMMMMMMMNOl'   .:    //
//    '.'cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;,l0WMMMMMMMMMMMMMMMMMMMNk:,:kNMMMMWk,...,dNMMMMMMMMMMWO;..:kWMMMMMMMMMMMMMMMNx;,c0WMMMMMMMMMMMMMMNo..'lXMMMMMMMMMWk,.'cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0dc,.....';oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l,;dX    //
//                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SecretsOE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}