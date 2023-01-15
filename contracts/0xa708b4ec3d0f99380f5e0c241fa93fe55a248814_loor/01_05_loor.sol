// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cozy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.  :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:    :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'     :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0oxNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.      ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'.dNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:        ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c. .xWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,         ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMXd'   'OMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.          ,0MMMMMMMMMMMMMMMMMMMMMMMMMWO;     ,0MMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.           :XMMMMMMMMMMMMMMMMMMMMMMMMWx'      ;KMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:             cNMMMMMMMMMMMMMMMMMMMMMMMWk'       :KMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,             .dNMMMMMMMMMMMMMMMMMMMMMMWk'        cXMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'              .OMMMMMMMMMMMMMMMMMMMMMMWk'         lNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.               .lxxxxxkOKXWMMMMMMMMMMMWk'         .dWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.                         ..;lxOKNWMMMMWk'          .xWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'                               ..,cx0NNx'           .kWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWNWMMMMMMMMMMMMMMMMMMMWO,                                     .,;.            'OMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMN0kkOXWMMMMMMMMMMMMMMMK:                          .,cc,.                      ,0MMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWNKkddx0NWMMMMMMMMMMXc                         ,o0NNOxxc.                    cXMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNKkoookKWMMMMMMNl.                      .'oXWMNd.'ONd.                  .kWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWXkolld0NWMNd.            .;odc'      .,kNWNl.;KMXl.                 :XMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWX00KNWMMMMMMMMMMWXOdlcoxo.            'xNMMWKd,      .,lxxdOXKk;                 .xWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMNKOxdddk0XWMMMMMMMMMNKx;.           .c0WMWOokNKc         .','.                   ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWNKkdolloxkKXWWMMMWK;            :KMMM0,.dNWx.                  ...           lNMMMMMMMMMWNXXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWX0kdolclodxOOc             .oKWM0:cKMWO'                'o0K0o.        .kWMMMMMWX0kxkOKWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNX0kdol;.               .cxkdoxkxl.             .lkXWKoo0o.       ,0WNX0kxxdxOKNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'                                       ,0WMMXc.:KK:       'odddxk0XWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWk'                                        .l0NW0;,OWWk.     .c0XNWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWO,                                           .:OK0KKkl,      'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWO,                                              .';;.        .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMW0;                                                            .lxkkOO0KXNNNWWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWO;                                                            .d0OOkkkxxxxxxkkO0KXNWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMW0;                                                            .lNMMMMMMMWWWWWWNNNWWWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWO,                                                             'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNx.                                                             .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNd.                                                              ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWx.                                                              .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMX:                                                               ;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWk.                                                              .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNl                                                               ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMM0,                                                              .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWx.                                                              ;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNl                                                              .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM0,                                                              ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWd.                                                             .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMK;                                                             .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWx.                                                             :XMMMMMMMMN0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXc                                                             .xWMMMMMMMWO;lXMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMO'                                                             :KMMMMMMMW0; .oNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWd.                                                            .dWMMMMMWXx'   .:OWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNl                                                             ,0MMMMMMNk,     .cKMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMK:                                                             cXMMMMMMMW0:   .dXWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMM0'                                                            .xWMMMMMMMMMXc..kWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMO.                                                            '0MMMMMMMMMMM0ldNMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMk.                                                            :XMMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWx.                                                           .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWd.                                                           .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMMMMM    //
//    MMMMMMMMMMMMNo.                                                           'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKloXMMMMMMMM    //
//    MMMMMMMMMMMMNl                                                            ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo..xWMMMMMMM    //
//    MMMMMMMMMMMMNl                                                            ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.  .xNMMMMMM    //
//    MMMMMMMMMMMMNl                                                            :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl.    .oKWMMMM    //
//    MMMMMMMMMMMMNo                                                            :XMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.        'dXMMM    //
//    MMMMMMMMMMMMWo.                                                           cXMMMMMMMMMMMMMMMMMMMMMMMMMMMXd,        ;xNMMM    //
//    MMMMMMMMMMMMWx.                                                           cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXo.    .dXMMMMM    //
//    MMMMMMMMMMMMMk.                                                           :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'  'OWMMMMMM    //
//    MMMMMMMMMMMMMO.                                                           :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd..kWMMMMMMM    //
//    MMMMMMMMMMMMM0,                                                           ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXodNMMMMMMMM    //
//    MMMMMMMMMMMMMK;                                                           .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMMMMM    //
//    MMMMMMMMMMMMMX:                                                            ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXc                                                             lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNc                                                             '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract loor is ERC1155Creator {
    constructor() ERC1155Creator("Cozy", "loor") {}
}