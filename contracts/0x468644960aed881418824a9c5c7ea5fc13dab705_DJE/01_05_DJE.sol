// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: David Johnston Editions
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
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWNNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;'''''''''''''''''''''':xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk,                          ;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.                            .:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWNK00O000000000kc.                                .ck00O000000000KNWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXx:..                                                              ..:xXMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWk,                                                                      ,OWMMMMMMMMMMMM    //
//    MMMMMMMMMMMM0'                                                                        ,0MMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                                                                        .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                                                                        .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                            ..;clooodoolc;..                            .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                         'cx0NWMMMMMMMMMMWN0xc'                         .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                      .ckNMMMMMMMMMMMMMMMMMMMWXk:.                      .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                    .c0WWNXK0KXWMMMMMMMWWXK0KXNWWO:.                    .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                   .xNW0xlc:::cokXWMMWKkoc:::clx0WNx.                   .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                  'OWNkc;;;;;;;;;cOXXOc;;;;;;;;;cxNWk'                  .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                 .kWWk:;;;;;;;;;;;cll:;;;;;;;;;;;:kWWx.                 .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                 cNMNd;;;;;;;;;;;;;;;;;;;;;;;;;;;;dNMNc                 .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                .xMMWk:;;;;;;;;;;;;;;;;;;;;;;;;;;:OWMMx.                .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                .OMMMNx:;;;;;;;;;;;;;;;;;;;;;;;;:xNMMMk.                .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                .kMMMMNkc;;;;;;;;;;;;;;;;;;;;;;ckNMMMMx.                .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                 lWMMMMW0o:;;;;;;;;;;;;;;;;;;:o0WMMMMNl                 .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                 'OMMMMMWNkl;;;;;;;;;;;;;;;;lkNMMMMMMO.                 .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                  ;KMMMMMMWXkl;;;;;;;;;;;;lkXWMMMMMW0,                  .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                   ,OWMMMMMMWXkl:;;;;;;:lkXWMMMMMMWO,                   .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                    .oXMMMMMMMWXOo:;;:oOXWMMMMMMWKo.                    .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                      'oKWMMMMMMMN0OO0NWMMMMMMW0o.                      .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                        .:d0NWMMMMMMMMMMMMWNOd;.                        .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                           ..;codkkkkkkxoc;.                            .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                                                                        .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                                                                        .xMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.                                                                        'OMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWx.                                                                      .xWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0l'.                                                                .'l0WMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWN0kxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxk0NMMMMMMMMMMMMMMMM    //
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
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DJE is ERC721Creator {
    constructor() ERC721Creator("David Johnston Editions", "DJE") {}
}