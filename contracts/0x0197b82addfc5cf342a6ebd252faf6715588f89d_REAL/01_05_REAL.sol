// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reality by LaurenMightExist
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWX0kxdddddxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kxdddddkOKNMMMMMMMMMMMMM    //
//    MMMMMMMMMW0dc,..         ..;lxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:,.          .';okXMMMMMMMMM    //
//    MMMMMMWKd,.                   .:xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o,                    .ckNMMMMMM    //
//    MMMMMKl.                         'dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:.                         ,xNMMMM    //
//    MMMNd.                             ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.                             ;0MMM    //
//    MMXc                                .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;                                .kWM    //
//    MXc                                  .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;                                  .kM    //
//    Wd                                    .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                                    ,K    //
//    K,                                     cWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                     d    //
//    k.                                     ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                                      :    //
//    x.                                     '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMo                                      ;    //
//    O.                                     ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd.                                     :    //
//    X;                                     lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'                                    .d    //
//    Mx.                                   '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                                    ;X    //
//    MNo                                  .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc                                  '0M    //
//    MMNo.                               .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc                                ,0MM    //
//    MMMWk,                             :0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'                            .lXMMM    //
//    MMMMMNd,                        .;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.                        .:OWMMMM    //
//    MMMMMMMNkc.                  .,l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx:.                  .,oKWMMMMMM    //
//    MMMMMMMMMMXOo:,..       ..;cd0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXko:'.         .;lxKWMMMMMMMMM    //
//    MMMMMMMMMMMMMMWXK0OkkkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo        ;KMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.     ,OWMMMMMMMMMMMMMM    //
//    WNXNXXXXXXXXXNNXXXXNXNWMMMMMMMMWNXNXXNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNXXXNXNWMMMMMMMMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNXNMMMMMMMW0oc:cd0XXNNXXXXXNNXXNXN    //
//    O,...................lNMMMMMMMWd'.............................................;0MMMMMMMMWo..............................................;0MMMMMMMMO;''.................l    //
//    k.                  .xMMMMMMMMO.                                              .kMMMMMMMMN:                                               cNMMMMMMMX;                   ;    //
//    O.                  ;XMMMMMMMNc                                               .kMMMMMMMMN:                                               .xMMMMMMMMx.                  :    //
//    0'                 .xMMMMMMMMk.                                               .kMMMMMMMMN:                                                ;XMMMMMMMX;                  l    //
//    X;                 ,KMMMMMMMN:                                                .kMMMMMMMMN:                                                .xMMMMMMMMd.                .x    //
//    Wc                 oWMMMMMMMO.                                                .kMMMMMMMMN:                                                 :NMMMMMMMK,                .O    //
//    Mx.               .OMMMMMMMWl                                                 .kMMMMMMMMN:                                                 .OMMMMMMMWl                ;X    //
//    M0'               :NMMMMMMMK,                                                 .kMMMMMMMMN:                                                  oWMMMMMMMk.               oW    //
//    MWl               oMMMMMMMMk.                                                 .kMMMMMMMMN:                                                  ;XMMMMMMMK,              .OM    //
//    MMk.             .kMMMMMMMWl                                                  .kMMMMMMMMN:                                                  .OMMMMMMMN:              cNM    //
//    MMNc             '0MMMMMMMN:                                                  .kMMMMMMMMN:                                                  .xMMMMMMMMo             .kMM    //
//    MMMO.            ;XMMMMMMMK,                                                  .kMMMMMMMMN:                                                   lWMMMMMMMx.            cNMM    //
//    MMMWl            :NMMMMMMMO.                                                  .kMMMMMMMMN:                                                   :NMMMMMMMk.           '0MMM    //
//    MMMMK;           lWMMMMMMMk.                                                  .kMMMMMMMMN:                                                   ;XMMMMMMM0'          .dWMMM    //
//    MMMMMk.          oMMMMMMMMx.                                                  .kMMMMMMMMN:                                                   ,KMMMMMMM0'          cNMMMM    //
//    MMMMMWd.         oMMMMMMMMx.                                                  .kMMMMMMMMN:                                                   ,KMMMMMMMK,         ,KMMMMM    //
//    MMMMMMNl         oMMMMMMMMx.                                                  .kMMMMMMMMN:                                                   ,KMMMMMMM0,        .OMMMMMM    //
//    MMMMMMMXc        lWMMMMMMMx.                                                  .kMMMMMMMMN:                                                   ;XMMMMMMM0'       .kWMMMMMM    //
//    MMMMMMMMX:       cWMMMMMMMk.                                                  .kMMMMMMMMN:                                                   :NMMMMMMMO.      .xWMMMMMMM    //
//    MMMMMMMMMX:      :NMMMMMMMO.                                                  .kMMMMMMMMN:                                                   cWMMMMMMMk.     .xWMMMMMMMM    //
//    MMMMMMMMMMXc     ,KMMMMMMMK,                                                  .kMMMMMMMMN:                                                   oMMMMMMMMd     .kWMMMMMMMMM    //
//    MMMMMMMMMMMNo.   .OMMMMMMMN:                                                  .kMMMMMMMMN:                                                  .xMMMMMMMWl    ,0MMMMMMMMMMM    //
//    MMMMMMMMMMMMWk.  .xMMMMMMMMo                                                  .kMMMMMMMMN:                                                  '0MMMMMMMX:   :KMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMM0;  lWMMMMMMMO.                                                 .kMMMMMMMMN:                                                  :NMMMMMMM0' .dNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXo.;XMMMMMMMX;                                                 .kMMMMMMMMN:                                                  dMMMMMMMMd.,OWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWOlOMMMMMMMWo                                                 .kMMMMMMMMN:                                                 '0MMMMMMMNdoXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNNMMMMMMMM0'                                                .kMMMMMMMMN:                                                 lWMMMMMMMWNWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWl                                                .kMMMMMMMMN:                                                .OMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'                                               .kMMMMMMMMN:                                                cNMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                                               .kMMMMMMMMN:                                               .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,                                              .kMMMMMMMMN:                                               oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                                             .kMMMMMMMMN:                                              ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.                                            .kMMMMMMMMN:                                             'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc.                                          .kMMMMMMMMN:                                          .;dKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkc.                                       .kMMMMMMMMN:                                       .,o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkc'                                    .kMMMMMMMMN:                                    .;o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.                                .kMMMMMMMMN:                                 'cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl;.                            .kMMMMMMMMN:                            .':d0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc,.                       .kMMMMMMMMN:                       ..;lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOdl;'.                 .kMMMMMMMMN:                 ..,:ox0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOxol:,'..        .kMMMMMMMMN:        ...,;codk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OxddolloKMMMMMMMMWkcllodxkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract REAL is ERC1155Creator {
    constructor() ERC1155Creator("Reality by LaurenMightExist", "REAL") {}
}