// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: narisofka q2
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc,,:dKWMMMMMMMWWWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.     .oXMMMWXkc;ckNMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'       .oNMNk,    .lXMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.        'OXo.      .oNMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,        .od.        ;KMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;.      .dc        'xNMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kdoox0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl;...'oOo'....,cxXWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;.     .,xXMMMMMMMMMMMWKOxxk0NMMMMMMMMMMMMWKxl:::clxxc'..,lkOOkkxxxkKNMMMM    //
//    MMMMMMMMMMMMWNNWMMMMMMMMMMWNKOxoccccokXWMMMXl.          ,okKXNMMMMWKc.    .;xXMMMMMMMMMMK:       cl.    ,dc'.     .lXMMM    //
//    MMMMMMMMMW0o;,,:oONMMMMWXkl,.         'oKMWd.              .';dKWMXc         :0WMMMMMMMMK:      .d0l,.';dd.        .xWMM    //
//    MMMMMMMMNd.      .;d0KOl'   ...         ,OXc          .,c:.    ,OWX:          'dKXK0Okxxkxc'..'cONMWXKKNMNd.       .xWMM    //
//    MMMMMMMM0,          ..  .:dOKKKOx:.      ;kl         'xNWWK;.   :XWd.           .;::,.   ..;oOXWMWKd:,;oKWWx.      ,0MMM    //
//    MMMMMMMMXc             c0WMMMMMMMWO;     .oO;       ;OWMMMWo..  'OMXc          .lOXNXx.     .:OWWO,     lNMWO;.   .oNMMM    //
//    MMMMMMMMMKc.          '0MMMMMMMMMMMO'     :XKd;'.,:xXMMMMMK:.   .OMMK:        ;0WMMMWx.       ,0K:      ;KMMMNOoccxXMMMM    //
//    MMMMMMMMMMNd.         .oXWMMMMMMMMMK,     cXMMWNXNWMMMMWXx;     ,0MMWk.      .kWMMMWk.        .dk.      .lKMMMMMWWMMMMMM    //
//    MWKkxOXWMMMWO,          ,xXMMMMMMMWk.    .dWMMMMMMMWX0xc'       lNMMMX:      '0MMMMXc         .oO;        ,kWMMMMMMMMMMM    //
//    0c.   'dXMMMM0,          .lXMMMMMWO,     ;KMMMWN0xl;..         .oNMMMNc      .oNMMMXl         '0WO,        .kWMMMMMMMMMM    //
//    c       cKMMMWk.          .oNMMMNx'     .kWMW0o,.   ..,.        ;KMMMK;       .dNMMMKc.      ,kWMWKl.       lNMMMMMMMMMM    //
//    O;.     .kMMMMO.           ,0MMNd.     .oNWKl.    .cOXNKl.      .lNMWd.        .lXMMMNOoc::lxXWMMMMNo.     .dWMMMMMMMMMM    //
//    WNOdc::lkNMMMXc            .kWNo.      :KW0;     .xWMMMWk.       .xWXc          .oNMMMMMMWWMMMMMMMWKc      ;KMMMMMMMMMMM    //
//    MMMMMMMMMMMW0:             .xNd.      .xWK;      lNMMWKd'         ,0No           cXMMMMMMMMMMMMWXkl'       oWMMMMMMMMMMM    //
//    MMMMMMMMMMW0,              .kO'       'ONo       ,xOx:.           .dNKl.        'OWWWWMMMMMMMNk:.          cXMMMMMMMMMMM    //
//    MMMMMMMMMMXc               ;0o.       .xK;                        .oNMNOl,....':ooc;;;lkXMMW0:.            .OMMMMMMMMMMM    //
//    MMMMMMMMMMXc              'kKc         :O:                       .cOkolccc:;,,'..       :0WX:              .dWMMMMMMMMMM    //
//    MMMMMMMMMMW0;            ,kWNo.        .od.             .,;:::cldxl'      ..,'.         .dW0,               oWMMMMMMMMMM    //
//    MMMMMMMMMMMMXx:..     .,oKWMMK:         ,Oo.          ,oxOXWWWWWNo.      ,kXNX0l.      .cKMWO:'..          .xMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWN0dl:;,;:lodxk0K0d,.      cXNk;.      .,;'..,dOxc;;.      .oNWMMMNx,. .'lONWKd:'';loc'      .lXMMMMMMMMMMM    //
//    MMMMMMMMMMMNOo;'...         ..,cdxo:,;:lddxkkdl:;,;:;.     ...           .;:cx0o.     .c0O,      'ldo:;,;ckXWWMMMMMMMMMM    //
//    MMMMMMMMMNk,.      ....         .cKWXd;.    .;okkxl'         .'.             .o;        ';.        .';ccll:;;l0WMMMMMMMM    //
//    MMMMMMMMWx.       ;OXX0x;        .dKl.      :OXNNNKo.         ckd;.         .dXO;        '.                   'OWMMMMMMM    //
//    MMMMMMMMX:        ,OWMMMK:       .ll.      cXMMMMMM0,         .kWWk'        ;KMMK:      .od'     .,lxo.       .oWW0dlxKM    //
//    MMMMMMMMNl         .;dOXW0;      ,o,      'OMMMMMMMX:          ,0MWx.       .,lol'     .dXW0l,',ckXNKd'       .oXd.   :K    //
//    MMMMMMMMMKc.          ..:odc,..'cOx.      :XMMMMMMMX:           cXMNl                .l0WMMMWNNX0dc,.         .oO,    .x    //
//    MMMMMMMMMMW0dc,.          .'cd0XWNo.      cXMMMMMMMK;           .xWMk.          .'.   .;d0WMMW0l.    .'.       :0k;..'lK    //
//    MMMMMMMWXkocc::cloc,.        .,xXWd.      :XMMMMMMMO.           .dWWx.          ;Ok'     .lKWk'     :KNk.      .c0XXXXWM    //
//    MMMMMWKo'       .lKN0o'         cXO.      ,KMMMMMMNo.           ;O0l.           '0Wx.      ,d:     .dWMK;        .;xXWMM    //
//    MMMMW0,           :KMWXl.       ,0No.     .dWMMMMWk'          .:l;.            .lNWx.       ''      ,kKd.           ;OWM    //
//    MMMMNl             cXMMK;      .oNMXo.     .xNMMNk'        ..:l,              .oXXd.        ..       ..              lNM    //
//    MMMMWd.            .kWMXc     .dNMMMW0o;..  .,ll;.        .o0O:              'kKx,          'l'                     .dWM    //
//    MMMMMXo.            :KNk'    .xWMMMMMMMWX0kdc'.          .oNM0,             .xXl.          .oXOl,....',coxkOxl;....:xNMM    //
//    MMMMMMWKxc:;;;;'.    ',.    .dWMMMMMMMMMMMMMWN0o'      .;kWMMNd.            ,0X:          .cKMMWNXKKXNWWMMMMMMWXKKXWMMMM    //
//    MMMMMMMMMMWWWWWNO:.         :XMMMMMMMMMMMMMMMMMWKo,..,ckXMMMMMNx'          .dNWKo,.    ..:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNx.       .xWMMMMMMMMMMMMMMMMMMMWNXXNWMMMMMMMMWKo,.     .:kNMMMWN0OkxkOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWk'     .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxxxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMW0l'..;dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWNXXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract narisofkaq2 is ERC1155Creator {
    constructor() ERC1155Creator() {}
}