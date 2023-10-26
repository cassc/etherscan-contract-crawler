// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fauves
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:.. .'cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWKkl;.        .oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNOl,.              .:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWKxc'.                   :XMMMMMMMMMWWMMMMMMMMMMMNOdox0NMMMMMMMMWX0kk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWXOo;.                      .lNMMMMMWKdc,;xNMMMMMMMMWd.   .lKWMMMMMNd'   ..,oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK00OO0KNWMMMMM    //
//    MMMMMMMMMMMN0d:.                         .,cOWMMMNd.    .oNMMMMMMMWo.     ,kNMMMMK;        .oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMMMMMMMMMMMMMMMMWXKOdl:'...    .';xNMMM    //
//    MMMMMMMMW0o,.                         ..;;cxNMMMWx.      'xNMMMMMMX:       ,OWMMMK;          .oXMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKko:,';cdKMMMMMMMMMWXOdc;..               .:xXW    //
//    MMMMMNOl,.                        .'',:ldkXWMMMMK,       'lKMMMMMWx.       .dWMMMX:            ;OWMWNk:;dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xl;'.        ;kXWMMMWKd:.                    ...':k    //
//    MMWXd,                        ..',:cdOXWMMMMMMMWd.       .lKMMMMMX:         lNMMMK;             ,kNKx,   :0WMMMMMMMMMMMMMMMMMMMMMNOdoxXMMMMMMMMW0d:..             .ckXNKd;.                  ..',;:clllx    //
//    Xxc.                       .::,:ldONMMMMMMMMMMM0,         ;KMMMMMN:        .dNMMMX:             .'xX0c    'xNMMMMMMMMMMMMMMMMMWKd,.   cXMMMMWKd;.                ..ckd,.                 ....,:lodk0XNWM    //
//    o.                      ..':clxKNMMMMMWWWWMMMMWx.          lXMMMMWo        'xWMMMWk.             'kNNo     .xNMMMMMMMMMMMMMMMXo.      ;0WMW0l.                .....;;.               ....';cdOKNWMMMMMMM    //
//    Xx:.                 ...':ox0NMWWNNKxl;,';cdXMWd.          .xWMMMMk.       .dNMMMMK,            .oNMMO'    .cKMMMMMMMMMMMMMW0:       .l0Kd,.              ..'..':lc.              ,lc;,:oOXWMMMMMMMMMMMM    //
//    MMWkc,.              .,:oOK0kdl:,'..       .o0Xd.           ;KMMMMk.       .oXMMMMX:            .xWNXk'    .lKMMMMMMMMMMMMXd.        ,o0Kdc;.     ...,:;'';cllxKNWo             .:ldOOKNMMMMMMMMMMMMMMMM    //
//    MMMMWNOc.            .,;'...               .;lxo.     .,.    lNMMM0'       .lXMMMMNl            .c0x;.      .xWMMMMMMMMMW0:         .,oKMMMNOl;;'':oxOkkO0KXNNWMMWl            .;:l0WMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMNc                                 .cO00c      .d:    .cXMMX;        :XMMMMW0;             ';,.       .lKMMMMMMMXo.           .lXMMMMMWNNXKXNWNK0koc;,,;:l00;          ..'lKWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMNc                             ..',ck00d.      .xk.     cXMWd.       'OMMMMMMx.             'c,         lXMMMMWO;            .'oNMMMMMMMMMMWKxc,.         ,x0d;.         .lXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMN0d'                          ..,;:cokKWX;       .xXc     .oKNO'       .xWMMMMMx.             .;oc.       'kWMMNd.            ',,kWMMMMMWXOdc,.              .cOX0d;.        ;dKWMMMMMMMMMMMMMMMMMM    //
//    MMMW0c.                       ...',;:ok0XWMMXl.        .,.       .',.        :KWMMMMK;             ..oKo.       .dX0:            .,;:xNMMNOdc;.                ..',;dXMMW0d;.       .;dXMMMMMMMMMMMMMMMM    //
//    MMWk,                     ...,;:cdO0NWMMMN0o'                                 cXMMMMMk.              ;KNk,        '.            .,;cOWMM0:                  ...,;coONMMMMMMW0o.        'dXWMMMMMMMMMMMMM    //
//    MMMXOxl'..              ..';oxkKWMMMWKOxl'.                                    cKMMMMNc              .xWMXo.                   .;;lKWMMMXo,.           ...'';:ldONWMMMMMMMMMMMK;         .cOWMMMMMMMMMMM    //
//    MMMMMMWXK0d.          .,;lxKWMMMMMMKc.                              ..         .lXMMMMK:              cNMMWKl.                .';dXMMMMMMMWKxllc;;,,,'',;:clodxxdooook0XWMMMMMMK;          .lKWMMMMMMMMM    //
//    MMMMMMMMMMNl          :ONWMMMMMMMMMXo.                              ;;.         .dNMMMM0,             ,0MMMMK;                .'dNMMMMMMMMMMMMMMNXK0kolc:;,..         .,kWMMMMMNc            ,OWMMMMMMMM    //
//    MMMMMMMMMMMk.         ;KMMMMMMMMMMMWKl.                             ,l'          .lXMMMWo             ,OWMMMWk'              ..'kMMMMMMMMMMMMMMWXOxl;.                  .:xXMMMO.             ,0MMMMMMMM    //
//    MMMMMMMMMMMx.        .cKMMMMMMMMMMMMMWKk;              ...'.        .;,.           cXMMWx.            ,OWMMMMWKd:.          .,,lXMMMMMMMWX0kdol;.                    ....':lkNXc             .,xWMMMMMMM    //
//    MMMMMMMMMMMK;        'dNMMMMMMMMMMMMMMMNl            .'lxxxl.         ;l.          .dWWk'             .dNMMMMMMMW0dc'     .;occ0MMMMMWKo,.                     ..,,'.,:clddoxXk.            .';kWMMMMMMM    //
//    MMMMMMMMMMMNl         cXMMMMMMMMMMMMMMMNl            ..lXWWNo.        .dx.          .oo.              .cKMMMMMMMMMMWXOkkxoclkk0WMMMMMWx.                   .',,;coooxOKXNWMMNx'              .cXMMMMMMMM    //
//    MMMMMMMMMMMWo         .kWMMMMMMMMMMMMMMMk.          ...dNMMM0;.        ,ko.                            ,OMMMMMMMMMMMMMMMMMWXNWMMMMMMMMWX0d:''...'..........,;coxOXNMMMMMMMW0:.              ..xWMMMMMMMM    //
//    MMMMMMMMMMMM0'         ,0MMMMMMMMMMMMMMMK,          .,dXMMMMMNOo;.      'xOl'                         .'oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXXK0OxdxdolodxkKNWMMMMMMMMMWKl.              .'.,0MMMMMMMMM    //
//    MMMMMMMMMMMMW0c.       .oNMMMMMMMMMMMMMMk.          'OWMMMMMMMMMWKx'     'OWXkl;.                    .,;oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMWNK0Od:.              ....;OWMMMMMMMMM    //
//    MMMMMMMMMMMMMMWk,       :KMMMMMMMMMMMMMM0c.        .:KMMMMMMMMMMMMWKc.    ;KMMMWXkolc;..         .,:c::xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWNNXKKK00KKXXNNNXK0kdl;'.              ....:c''oKWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWXOl;,'':dKMMMMMMMMMMMMMMMWKc.     .:kNMMMMMMMMMMMMMMNk,   .xWMMMMMMMMWX0kooxdl:cllloookNMMMMMMMMMMMMMMMMMMMMMNKOdlc::::c:;;,,''...........''..                     .cdxdoxXWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWWNK0XWMMMMMMMMMMMMMMMMMXc.    'xNMMMMMMMMMMMMMMMMMXo.  ,OWMMMMMMMMMMMMMMMWNNXKKNNWMMMMMMMMMMMMMMMMMMMMMWk;.                                                 ..;dkO0KXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.  .lXMMMMMMMMMMMMMMMMMMMWk,  ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWkc,.                 ..          .               ..',;lkKXWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo,,dXWMMMMMMMMMMMMMMMMMMMMMKc.;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOxdol:,,,...,'..,:oo:,,,,,,,;:ccc:,...'......':lodOXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKNMMMMMMMMMMMMMMMMMMMMMMMMNOd0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0OOdoxxdodkO0OxxkxkOO0KXNNNXK0OO0O000OO0XNWMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FVS is ERC1155Creator {
    constructor() ERC1155Creator() {}
}