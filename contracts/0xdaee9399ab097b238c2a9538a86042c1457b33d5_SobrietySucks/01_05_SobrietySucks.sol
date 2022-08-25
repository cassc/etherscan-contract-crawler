// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TravisWasHere
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMXkl;..      ..';cokKNMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0o,.                ..,:ok0NMMWWWMMMMMMMMMMMMWNKOOxddddddxkkkxddddONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXo.                         .';;,,;lOWMMMMN0xol;'.                   ,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWKc       ..,:cloll;.                 ;KMNOl,.                          'oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMNk:.       :OXWWXOdc;..                 ,Ok;.     .,;,.       .,co:.        .,o0NXXWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMNx,          .odc,.       ...              .     ,looc'     .,lkKKx:.    .;,.    .'..;kWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMW0;     ,xx;           .,:c:,..     .;okd.        .;;.     .;d0NNOl'     'lO0d'         cNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMNd.    ,odl;.      .,cdxxo:.      'coddl,.                ,d0WN0o,     .;col,.           .oXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMWKc     .'.      .:ok00xc'.     .,:cc:'                  .cONN0o,.     ..,'.        .,c:.    ,kWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMK:           'cdOXXOo;.      ..','.       .;od'       .okKN0o,.                    'xNMW0:    .dWMMMMMMMMMMMMMMMMMMM    //
//    MMWK:        .;oONNKxc'         ..        .;lkXWMX:       ,xOd;.                        .dNMWNo.   .dWMMMMMMMMMMMMMMMMMM    //
//    WKo'     .,lkXWXkl,.                     .dNMMMMXc                                       .kMMMNo    .OMMMMMMMMMMMMMMMMMM    //
//    x.     .c0NN0d:.                          .xWMMX:                           'cd,         .kMMMMX;    cNMMMMMMMMMMMMMMMMM    //
//    o      :0kl,.                  'c'         lWMMk.                       .,lkXWMKl,.   .':kNWMMMWd    '0MMMMMMMMMMMMMMMMM    //
//    Nl     ..                  .;oONM0;.     .c0WWXl.                     ,lONWWMMMMMNK0O0KNWMWMMMWMk.   .kMMMMMMMMMMMMMMMMM    //
//    Wo                      'cxKWMMMMWNOdolokKWNOl'                    ,lONMMMMMMMMMMMMMMMMMMMMWMMMMO.   .kMMMMMMMMMMMMMMMMM    //
//    O,                  .;oONWMMMMMMMMMMMMMMWXd,         ..         'lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.   .OMMMMMMMMMMMMMMMMM    //
//    .               .'cxKWMMMMMMMMMMMMMMMMMXd'       .,cc;.     .'ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo    ,KMMMMMMMMMMMMMMMMM    //
//    l.           .;oONMMMMMMMMMMMMMMMMMMMMWo      .:d0O:.      c0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,    lWMMMMMMMMMMMMMMMMM    //
//    Nl       .'cxKWMMMMMMMMMMMMMMMMMMMMMMMM0c,':dOXWMMd       'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo    '0MMMMMMMMMMMMMMMMMM    //
//    c.      ,ONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWWMMMMMMNx,     oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.   .dWMMMMMMMMMMMMMMMMMM    //
//    .       oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0ddkXWO'    :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.    cNMMMMMMMMMMMMMMMMMMM    //
//    klc,    .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.   ld.    ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.    :XMMMMMMMMMMMMMMMMMMMM    //
//    MMMXc    .dNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc    .     :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:.    cXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMXl     ;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.       .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo.    .dNMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMNx'    .;xXWMMMMMMMMMMMMMMMMMMMMMMMNXK0k,      'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNOc.    .:0WMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMWKo.     'cxKNWMMMMMMMMMMMMMMMNOo:,..         .':cox0XNWMMMMMMMMMMMMMMMMMMMWN0o,.     ;kNMWNNNWWMMMMMMMMMMMMMMMMMM    //
//    MMWMMMMMWXd,.     .':ldk0KXXNNNNXX0d,                      .',cdkOkkOKNMMMMMMWN0xl,.        ';;:,''',:dKWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMN0o;.         ...''''...           .....                  .;dkkxoc;'.                       :0WMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWXOdl;'..                 .;ldk0K0ko:.                              ..          .'.       .:dKWMWWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNX0Oxddol,          ,0NKkdc,.                             .;c:,.      ':okko.          .:ddoxXWMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0c.    .;.    .,.       .','..       .;:.         ;oc'     .;dONXx:.    .;dx;         :XMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNx.    'dOOc.        .;cool:'.     .'cdkkd,         ..    .;xKWNOl'     .cxxo:.         'OWMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMK:     'cc'      .,cdkOxl,.     .;cllol;.                ,dKWNOo,.    .';:;.         .    .lXMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM0,            .;lx0X0d;.     ..,;;;'        .'.        .:kNNOo,        ..         .;oO0o.    ,OMM    //
//    MMMMMMMMMMMMMMMMMMMMMM0,         .;lkKNKxc'.      .....        .,cx0No       .xX0o,.                     .cOWWW0;    .kW    //
//    MMMMMMMMMMMMMMMMMMMMNO,       'cxKWXOo;.                   ..;x0NMMMK:        ,;.                          .kMMMXc    '0    //
//    MMMMMMMMMMMMMMMMMMNx,.    .;oONWKdc'                        .,OWMMW0,                           '.          lWWWMK;    c    //
//    MMMMMMMMMMMMMMMMMMx.     .dNXkl,.                             ;XMMX;                        .,lONO'        'OWMMMMx.   .    //
//    MMMMMMMMMMMMMMMMMMK:.    'l:.                  .,lkd.         cNMW0,                     .,oONMMMWXxl:::cokXWWMMMM0'        //
//    MMMMMMMMMMMMMMMMMMWO'                       .:d0WMMWOc,...':lxXWXk:.                  .,o0NMMMMMMMMMMMMMMMMMMMMMMMK;        //
//    MMMMMMMMMMMMMMMMMMWd.                   .,lkXWMMMMMMMWNXKXNWMN0l'                   ,oONMMMMMMMMMMMMMMMMMMMMMMMMMMK,        //
//    MMMMMMMMMMMMMMMMMNd.                 ':xKNMMMMMMMMMMMMMMMMNkl;.        ';'       ,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.        //
//    MMMMMMMMMMMMMMMMMX:              .;oOXWMMMMMMMMMMMMMMMMMWK:        .:odc'     .cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd    '    //
//    MMMMMMMMMMMMMMMMMWKl.         .:dKWMMMMMMMMMMMMMMMMMMMMMMk.    .,lkXW0,       lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;    l    //
//    MMMMMMMMMMMMMMMMMWKl.      'lOXWMMMMMMMMMMMMMMMMMMMMMMMMWW0xodkKWWMMW0:.     .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo    '0    //
//    MMMMMMMMMMMMMMMMM0,       ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWWWNl     oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.   .dW    //
//    MMMMMMMMMMMMMMMMMKc.      '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd,';kXd.    cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.    oNM    //
//    MMMMMMMMMMMMMMMMMMWK0k,    ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.   .;.    cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.   .lNMM    //
//    MMMMMMMMMMMMMMMMMMMMMW0,    .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.        .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd.    .dNMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMK:     ,xNMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMNl       ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx,     ;OWMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNx,     'lONMWWMMMMMMMMMMMMMMMMMMMMWWN0d'      .oXWMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl'     'xNMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWXd,      'cdOKNWMMMMMMMMMMMMMWX0klc,.          'lONMMMMMMMMMMMMMMMMMMMMMWXkl,.     ,dXMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWMMNkc'       .';clodddxdddoc:,..       'lOkc.     ':ok0XNWMMMMMMMMWNK0xl;.      .ckNMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWMMMMMWXOd:'.                      ..':oONMWMWKd;.      ..',;::::::;,'.       .,lkXWMMWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdlc;,'.........',:cok0XNMMMMMMMMMMWKxl;'.                  .':lx0NMMMWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK0OOOOO0KXWMMMMMMMMMMMMMMMMMMMMMWXOdc;'.        ..;cdOXWMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SobrietySucks is ERC721Creator {
    constructor() ERC721Creator("TravisWasHere", "SobrietySucks") {}
}