// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Solvitur Ambulando
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                                                //    //
//    //                                                                                                                                //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMXdccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclOWMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.                                                                        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.                                                                        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.                                                                        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.       .ckko.   'okkko,          ,xkkx,          'dkkl.    ,xkk;        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.       .kMMK, ,xXMWXd'           cNMMNl          :NMMW0;   cNMWo        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.       .kMMXdxXMWKo.             cNMMNl          :NMMMMXo. cNMWo        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.       .kMMMWMMWk'               cNMMNl          :NMMWWMWO;lNMWo        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.       .kMMMWWMMXl.              cNMMNl          :NMMOdKMMXXWMWo        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.       .kMMNo;kWMWO,             cNMMNl          :NMMd.'kWMMMMWo        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.       .kMMK, .lXMMXo.           cNMMNl          :NMMd. .lXMMMWo        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.       .xWW0,   ,ONWNk,          :XWWXc          :KWNd.   ,ONWNo        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.                                                                        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.                                                                        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.           .';::;'.              .,,,'           .,,,.                  cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.         .lONWMMWN0o.           .oOOOx;          ,xOOc                  cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.        .kWMXxlldKWW0,         .ckOOOOd'         ,xOOc                  cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.        oWMXc    ;KMMk.        ;xOk  kOo.        ,xOkc                  cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.       .kMMO'    .xMM0'       'dOO    Okc.       ,xOOc                  cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.       .dWMK;    '0MMk.      .lkOOOOOOOOk;       ,xOkc                  cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.        ,0WWKo;;l0WMK:       :kOxc;;;:okOd'      ,xOOo                  cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.         .dKWMWWMWXk,       ,xOkc.    .dOOo.     ,xOOOkkkOkOOkk:        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.           .;lool:.         '::;.      .::;.     .;:::::::::::;.        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.                                                                        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.                                                                        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.       .cdxd;    'oxdl.       ':odxxxddl;.       'oxxxxxxxxxxxo.        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.        .ckOxc. ;xOkl.       :xOkdllloxOOd,      ,xOOxooooooooc.        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.         .;xOkolxOx:.       .lOOkl       x:.     ,xOkl'                 cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.           ,dOOOOd,            kOOkkkxxxd        ,xOOkxxxxxxxxc         cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.            'dOOd'          ., oc:clodxkOkc.     ,xOOxllllllll,         cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.            .lOOo.          ;kO        dOOx'     ,xOkc                  cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.            .lOOo.          .ckOOxdoodxkOx:.     ,xOOxddddddddo,        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.            .:dd:.            .;coddddol;.       .ldddddddddddo,        cNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.                                                                        lNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO.                                                                        lNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMO'                                                                        lNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMKl,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;xWMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //                                                                                                                                //    //
//    //                                                                                                                                //    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SLVDBYWLK is ERC721Creator {
    constructor() ERC721Creator("Solvitur Ambulando", "SLVDBYWLK") {}
}