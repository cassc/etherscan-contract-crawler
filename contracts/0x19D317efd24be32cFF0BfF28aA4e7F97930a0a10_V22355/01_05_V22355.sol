// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DISTURBIA V2.2023.55
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXKK0000OOO000KKXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kdolc;,'........  .....'''',;cldxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdlc;'.                       ..      .  .';:ldOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKko:'..  ..                         ..      .    .   ..':ok0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKxc,..       .                          ..      .    .   .     .,lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl,..           .                          .            .   .         .,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl,.               .                          ..           .   .             .:xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc'.                  .                          ..      .    .   .                'ckXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo,..   .                .                          ..      .    .   .                  .'o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNkc.  ..   .                .                          .       .    .   .                     .:kNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNx;.    ..   .                                           .       .        .                       .;kNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNx;.      ..                    .                          ..           .   .                 .       .;xNMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNk;.        ..   .            .   .                          ..      .    .   .                 .       .  ,kNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMW0:.          ..   .                                           ..      .    .   .                 .       .   .c0WMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNd.            .                                                ..          ..   .                 .       .     .oXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMW0c.             ..                                               .       .    .   .                 .               ;0WMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNd...             ..                    .                          ..      .    .   .                 .                .xNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXl. ..           ....                    .                          ..      .    .   .                 .       .         .lXMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMK:    .             ..   .                .        .,,.              .       .   ..   .              .,..                  .:KMMMMMMMMMMMM    //
//    MMMMMMMMMMM0;     .           . ..                    .       ,kNNk'             .       .        .             'OXl.                    ;0MMMMMMMMMMM    //
//    MMMMMMMMMM0,      .             ..  ..                .       'o00o.             ..      .        .             ,0Wo.       .             ,0MMMMMMMMMM    //
//    MMMMMMMMMK;       .            ...  .......   .. ..   .      .....              ......  ...  .    .      ....   ;KNo.       .              ;0MMMMMMMMM    //
//    MMMMMMMMKc.       .             ..  'dOOOOOOkxkOOOOx:..    ,xOOOOOo.           'dOOOOOOOOOOOkl.   ..'okOOOOOOOOOKWNo.       .               :KMMMMMMMM    //
//    MMMMMMMNl.        .             ..  ;KWOollkNWOollkNXl.    .clloOWK,           :KXklllllllldKNd.   .xWKollllllllxNNo.                        oNMMMMMMM    //
//    MMMMMMWx.        ..             ..  ;KNo   ;XNl   ;0Wd.         oWK,           :KK:        .dWO.  .'kWx.        ,KWo.       .                'kWMMMMMM    //
//    MMMMMM0;          .             ..  ;KNo   ;XNl   ;0Wd.         oWK,           :KK:      . .dWO.  .'kWx.        ,KWo.       .                .;0MMMMMM    //
//    MMMMMNo.  .      ..             ..  ;KNo   ;XNl   ,0Wd.         lWK,           :KK:      . .dWO.  .'kWx.        ,KWd.       .                ..lNMMMMM    //
//    MMMMMO'.         ..             ..  ;KNo.  :KNl   ,0Wd.         lWK,           :KK:      . .dWO.  .'kMx.        ,KWd.      ..                ..'kMMMMM    //
//    MMMMNl..         ..             ..  ;KNo. .:KNl   ,0Wd.         oWK,           :KK:      . .dWO.  .'kWx.        ,KWd.       .                .. cNMMMM    //
//    MMMM0,            .             ..  ;KNo.  :KNl.  ,0Wd.   .:oood0WNkoodl'      :XX:      . .dWO.  ..xWKxooooooookNWd.       .                .. 'OMMMM    //
//    MMMWd.            .             ..  .ld,   .ld,   .ld;.   .cxxxxxxxxxxxd,      .od,      .  ;dc.  ...lxxxkkxxxxxkxx:.       .                .. .dWMMM    //
//    MMMXc...         ..             ..   .        .       .      .                   ..      .   ..   .                         .                ..  :XMMM    //
//    MMMK, .          ..             ..            .       .                          ..      .    .   .                                          ..  ,0MMM    //
//    MMMO'             . .'.      .,,'.   .                .   .'.                    ..      .    .   .  ..             .  .,.                       .OMMM    //
//    MMMO.            ...d0,     .lXKl.   .                .  .o0:                    ..      .    .   . ,0d.              .dNk'                  ..  .kMMM    //
//    MMMx.  .         ...kK;     .,c:'.        .   .       . ..dXc.. .                ..     ..   ...    ;Kx.   .         ..,c,. .          ....  ..  .xMMM    //
//    MMMx.     .:xxxxxxxkXK;   .cxxkx:.      .lxxxxxxxxd;  ..ckKN0xxxxc.   :o'       ;o,   ;dxkkxxxxkd'. ;KXkxxxxxxx:.   'oxxko.       ;xkxxxxxxxo,.  .xMMM    //
//    MMMk.  .  ,OKc''',;:OK;    .,;xXo.      :Kk;',,,'cOl. ...;kXd;,''.   .dK:      .o0c   .';kXx;,:OK:. ;KO:,,,,,cKO'   .',:OK; .    .c0o,,,,,;kXl.  .kMMM    //
//    MMMO.  .  ,00'    ..xK;      .oXo.      :K0oclllloo;. .. .dXc        .dK:      .o0:     .dK:  .,,.. ;Kx.     .O0'      .kK;       .,;;:cloxKXl.  .kMMM    //
//    MMM0'     ,OO'    ..xK;      .oXo.      .:oloooookXd. .  .dX:   ..   .dK:      .o0:     .dK:  .   . ;Kx.     .O0'   .  .kK;..    .;O0xdolcckXl.  '0MMM    //
//    MMMK;     ,OO'   ...xK;      .oXo.   .  'o;      ;Kx. .  .dKc. .xO'  .dK:      .o0:     .dK: ..   ..;Kx.     'O0'   .  .xK; .    .oXo.    .oXo.  ;KMMM    //
//    MMMNl.    'kXxoooddxKK;   'ldd0N0dol'.  ;00doooookKo. .  .lKOdoxKO'   cKOdoooood00:  .;od0NOddc.  . ;KKdoooooxXk.  .;ooxKNkoo:.  .lX0dooodd0Xo.  lNMMM    //
//    MMMMk.    ..;ccccclcc:.   .:cccclcc:..  .,cccccccc:.  .   .,cccc:'     ':ccccccccc.   ,ccccccc:.  . .;cccccccc;.   .,cccccccc;.   .:cccccccc:'. .kMMMM    //
//    MMMMX:.           .             ..   .                .                          ..           .   .                 .       .                .. ;KMMMM    //
//    MMMMWx..          .             ..  ..        .                                  ..           .   .                         .                ...dWMMMM    //
//    MMMMMK:.          .             ..   .                                           ..      .    .   .                         .                ..;KMMMMM    //
//    MMMMMWk.          .             ..   .                .                          ..      .    .   .                                           .xWMMMMM    //
//    MMMMMMNl.        ..             ..   .                .                          ..      .   ..   .                 .       .    .           .oNMMMMMM    //
//    MMMMMMM0,        ..             ..  ..                .                          .       .        .                                          ;KMMMMMMM    //
//    MMMMMMMWk'        .             .    .                .                          .       .        .                                         .kWMMMMMMM    //
//    MMMMMMMMWx.       .             ..   .                .                          ..      .    .   .                ..                      .dWMMMMMMMM    //
//    MMMMMMMMMNd.      .             ..   .                .                          ..      .        .                ..       .             .dNMMMMMMMMM    //
//    MMMMMMMMMMNo.     .            ...   .                .                          .       .    .   .                 .       .            .dNMMMMMMMMMM    //
//    MMMMMMMMMMMNd.   ..             ..   .                .                          .       .        .                ..                   .dNMMMMMMMMMMM    //
//    MMMMMMMMMMMMWx.   .             ..   .                .                          .       .        .                 .                  'kWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWO,  .             ..   .                .                          ..      .    .   .                                   ;0WMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMKl..             ..   .                .                          ..      .        .                .                .lKMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNk;             ..   .                .                          .       .                                         'xNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMKl.           ..   .                .                          ..      .    .   .                         .    .lKMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWO:.         ..   .        .       .                          ..      .    .   .                 .       .   :OWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNk;.       ..   .        .       .                          ..           .   .                 .       ..,xNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNx;      ..  ..        .       .                          ..      .        .                        .:xXMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNx;.  ...   .        .       .                          .       .    .   .                      .;kNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNOl'...                    .                          ..      .    .   .                    .cONMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc.   .                .                          ..      .        .                 .:dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o;..        .       .                          ..      .        .              .,o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d;.              .                          ..      .    .   .           .;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxl;.          .                          ..      .   ..   .       .,lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xl:.      .                          ..      .    .   .   .,lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdl:'..                          ..      .    ...':ldOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxoc;'...                  ..    ..',;coxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0kkxdolccccc:::ccclodddxk0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract V22355 is ERC1155Creator {
    constructor() ERC1155Creator("DISTURBIA V2.2023.55", "V22355") {}
}