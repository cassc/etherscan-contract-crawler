// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Luna's Tributes
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0Oxdolcc::;;;,,;;;;::clodxkOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kdl:,..                            ..';coxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc;..                                           .,:okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl;.                                                      .,cd0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.                                                              .'cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc'                                                                      .;d0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc.                                                                            .;dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l'                                                                                  .:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.                           ..,:cloddxkkkxc.                                            'dKWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNx,                        .,cox0KNWMMMMMMMMNk;.                                               .l0WMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNx,                     .,cdOXWMMMMMWNWMMMMMNx,                                                    .c0WMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNk,                    .cx0NMMMMMMMMMWk:kMMMWk,                                                        .lXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMW0:                   'lkXMMMMMMMMMMMMNd. dMMKc.                                                           'xNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMXo.                 .:kNMMMMMM0ook0XWMXl.  cNk'                                                               ;0WMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0;                 'oKWMMMMMMMMNk, ..,c,    ,o.                                                                 .dNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNx.                ,xXMMMMMMMMMMMMMNx'       .dKOxoc:'                          .c'                                 :KMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXl.               'xNMMMMMMMMMMMMMMMMMK;     .xWMMMN0x:.                        'kNl                                  'OWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMK:               .lXMMMMMMMMMMMMMMMMMMNd.     oWMNkl,.               ',.        ,0MMd                                   .kWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMK;               ,OWMMMMMMMMMMMMMMMMMMXc      ;XMMk.                  'xK0xl:'..:KMMMk.                                   .xWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMK;              .lXMMMMMMMMMMMMMMMMMMMK;    .;;cONMK,                   .cKMMMWKKNMMMMXc..                   ':'            .xWMMMMMMMMMMM    //
//    MMMMMMMMMMMX;              .xWMMMMMMMMMMMMMMMMMMMKc,:lx0XWx. ,o0c                     'kWMMMMMMMMMMWXKOkdoc:.           .oKo.            .xWMMMMMMMMMM    //
//    MMMMMMMMMMNc              'OWMMMMMMMMMMMMMMMMMMMMNKNMMMMMNc    ..                      .cKMMMMMMMMMMMMMMMNOl.             .               .OMMMMMMMMMM    //
//    MMMMMMMMMWo              'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'                             ;KMMMMMMMMMMMMXkl'                                 ;KMMMMMMMMM    //
//    MMMMMMMMMO.             .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                            cXMMMMMMMMMMMNd'                                     lNMMMMMMMM    //
//    MMMMMMMMX:             .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                          .oNMMMMWXXWMMMMNc                                      .kMMMMMMMM    //
//    MMMMMMMMd.             lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                         .xWNKkdc,..:kNMMMx.                                      ;XMMMMMMM    //
//    MMMMMMMK;             ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                         ;l:'.        ,dXWX;                                      .xMMMMMMM    //
//    MMMMMMMx.            .dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'                                        .cOl                                       :NMMMMMM    //
//    MMMMMMNc             ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                                          ..               .;.                     .OMMMMMM    //
//    MMMMMM0'             oWMMMMMMMMMMMMMMMMMMWX0OO0KNWMMMMMMMMx.                                                          'OO;.,co,                oMMMMMM    //
//    MMMMMMx.            .kMMMMMMMMMMMWXNXOdlcccccc,..;lxKWMMMMX;                                                        ..cKMNNWWd.                :NMMMMM    //
//    MMMMMMo             '0MMMMMMMMMNxdkl'  ,;',..,ll.   .;xNMMMk.                                                     .;oONMMMMMNo.                ,KMMMMM    //
//    MMMMMWc             ;XMMMMMMMNk,;d, .:OO;.cOo. :d.    :XMMMWo                                                        .;OMMN000x,               '0MMMMM    //
//    MMMMMN:             ;XMMMMMMXc .dc  lWMWX0xckO. ol   ;KMMMMMNl                                                        oWO,.....                .OMMMMM    //
//    MMMMMN:             ;XMMMMMXc  .d: .kMMMMMXkKK; co. cKMMMMMMMXc                                                        :l.                     .OMMMMM    //
//    MMMMMNc             ,KMMMMMd.   lo  ;KMMMMMMNo..dc,kNMMMMMMMMMNo.               ..                                                             .OMMMMM    //
//    MMMMMWl             .OMMMMNc    .oo. .cxOOko,.'k0ONMMMMMMMMMMMMWx.             .oO;                                                            '0MMMMM    //
//    MMMMMMd             .dMMMMW0o;.   ;lc,......:dXMMMMMMMMMMMMMMMMMMK:            ;KMK:                                                           ;XMMMMM    //
//    MMMMMMk.             cNMMMMMMWKOdlccdO0000KNWMMMMMMMMMMMMMMMMMMMMMNk,          dWMMXc                                                          cWMMMMM    //
//    MMMMMMK,             .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,       ,KMMMMNl                                                        .dMMMMMM    //
//    MMMMMMWl              cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;.    oWMMMMMNo.     ..',:.                                           '0MMMMMM    //
//    MMMMMMMk.             .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl:';0MMMMMMMWkodxk0KXNWO,                                           cWMMMMMM    //
//    MMMMMMMN:              ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0OOkxdolc::,'ckXWMMMMMMMMMMMMMNd.                     ..                    .kMMMMMMM    //
//    MMMMMMMMk.              cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;.              .:okKWMMMMMMMW0;                  ..:oOO;                    cNMMMMMMM    //
//    MMMMMMMMNl               lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl'.               .,:oxO0XXx.            ..';cox0NWMX:                    '0MMMMMMMM    //
//    MMMMMMMMMK,               lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o;.                  ..,lxddoooooodxkO0XNWMMMMMMX:                    .dWMMMMMMMM    //
//    MMMMMMMMMMk.               cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxc'.                 ;KMMMMMMMMMMMMMMMMMMMMMK;                     cNMMMMMMMMM    //
//    MMMMMMMMMMWd.               ;0MMMMMMMMMMMMMMMMMMMKxXMMMMMMMMMMMMMMMMMMMMMMk:.                 cNMMMMMMMMMMMMMMMMMMWO,                     ;KMMMMMMMMMM    //
//    MMMMMMMMMMMNl                .xWMMMMMMMMMMMMMMMWO'.xMMMMMMMMMMMMMMMMMMMMMN:                   .dWMMMMMMMMMMMMMMMMNd.                     ,0MMMMMMMMMMM    //
//    MMMMMMMMMMMMNl                .cKMMMMMMMMMMMMMWx.  oMMMMMMMMMMMMMMMMMMMMWd.      'oko;.        .kMMMMMMMMMMMMMMW0;                      '0MMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNl.                .o0NWMMMMMMMMNo.   :NMMMMMMMMMMMMMMMMMMM0'     ,xXMMMWKx:.      ,0MMMMMMMMMMMMXl.                      ,0MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNd.                 ..;ldOKNMMXc     ,KMMMMMMMMMMMMMMMMMMNc    ;xNMMMMMMMMMXkl,.   :XMMMMMMMMMXd.                       ;KMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWk.                      .':c,      .OMMMMMMMMMMMMMMMMMWd..:okNMMMMMMMMMMMMMMN0d:..lNMMMMMWKo'                        cXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMM0;                                .xMMMMMMMMMMMMMMMMMWxlOWMMMMMMMMMMMMMMMMMMMMWXkONMMMNOc.                        .dNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXo.                               'ox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o,                          ;0WMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWO,                                  .,:ox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo,.                          .dNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNd.                                    .,oKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dc'                            .:0WMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMKl.                              .:ox0NWMMMMMMMMMMMMMMMMMMMMMMMMWX0xl:.                               ;OWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWKl.                            .,:ldkO0KXNWWWMMMMWWWWNXK0Oxdl:,.                                  ;kNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWKo.                                 ...'',,;;;;,,,'....                                      .;kNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd,                                                                                      .l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc.                                                                                .;xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx:.                                                                          .,o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc'                                                                    .;d0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.                                                            .,lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo:'.                                                   .;lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkoc,..                                       .':lx0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdoc;,...                    ...';:lox0XNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0OOkxddooooooooddxxkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                     ╔╦╗╦═╗╦╔╗ ╦ ╦╔╦╗╔═╗╔═╗                                                                   //
//                                                                      ║ ╠╦╝║╠╩╗║ ║ ║ ║╣ ╚═╗                                                                   //
//                                                                      ╩ ╩╚═╩╚═╝╚═╝ ╩ ╚═╝╚═╝                                                                   //
//                                                             ╔╗ ┬ ┬  ╦  ┬ ┬┌┐┌┌─┐  ╦  ┌─┐┌─┐┌┐┌┬┌─┐                                                           //
//                                                             ╠╩╗└┬┘  ║  │ ││││├─┤  ║  ├┤ │ │││││└─┐                                                           //
//                                                             ╚═╝ ┴   ╩═╝└─┘┘└┘┴ ┴  ╩═╝└─┘└─┘┘└┘┴└─┘                                                           //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LUNAT is ERC1155Creator {
    constructor() ERC1155Creator() {}
}