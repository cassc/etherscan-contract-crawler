// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Headphone Homies
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxolc:;;,,,,,;:cloxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXko:'.                    .':okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o;.                              .;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWKd,.          ..,;:cccccc:;,..           ,o0WMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMW0c.        .,cdOKXWWMMMMMMMMWWNKOdl,.        .:ONMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMW0c.       .cxKWMMMMMMMMMMMMMMMMMMMMMMWKkc'       .:OWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXo.      .;xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXk:.      .lKMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMW0;      .:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c.      ,OWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWk.      ,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;      .xWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWk.     .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.     .dWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMO.     .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.     .xWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMK;     .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.     '0MMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWo      cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl      cNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM0,      .;cxXMMMMMMMMMN0kOXWMMMMMMMMMMMMMNOkOXMMMMMMMMMNkc;.      .OMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMx.          oWMMMMMMWk,.  'dNMMMMMMMMMMNx,   'xNMMMMMMWd.          dWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXc          ;0MMMMMMWd.      lNMMMMMMMMNo.     .oNMMMMMMK:          :KWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNd'          ,0MMMMMMMO'       .xWMMMMMMMk.       .kMMMMMMMK;          .oXMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMM0'          .dWMMMMMMNl         :XMMMMMMNc         :NMMMMMMMk.          .OMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMX:          '0MMMMMMMK;         '0MMMMMMK,         '0MMMMMMMK,          ;KMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWx.         ,KMMMMMMM0'         .kMMMMMM0'         .OMMMMMMMX:          oWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMK,         '0MMMMMMMK,         .OMMMMMM0,         'OMMMMMMMK,         'OMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWo         .dWMMMMMMNc         ;XMMMMMMNc         :XMMMMMMMk.         cNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMO.         ,0MMMMMMM0,       .kWMMMMMMMO'       'OMMMMMMMK;         .xMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNl.         ;KMMMMMMW0c.   .:OWMMMMMMMMW0c.   .:0WMMMMMMX:          cXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNOdo,       lNMMMMMMMWKkxkKWMMMMMMMMMMMMWKkxkKWMMMMMMMWd.      'ldONMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMKl.  .'lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKo,.  .cKWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWKOOKNWMMXOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOXWMMNKOOKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWk, .:xXWMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc. 'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMK,     .:dOXWMMMMMMMMMMMMMMMMMMWX0d:.     'OMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMK;         .;coxO0KXXXXXXK0Okdc;.         ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;.            ..........            .,oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'.                          .':d0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xo:,..              ..,:lx0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOkxddooooddxkOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HH is ERC721Creator {
    constructor() ERC721Creator("Headphone Homies", "HH") {}
}