// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hoppy Holiday Frogs!
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo'. ..;oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,.      .,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'          'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKl.           cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0d,            'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO:.            .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk,.            .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx,.            .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo..            .lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'               .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNKOo,.                 .;dOXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK00OOkkxxxddooollc:;'..                       ..,;:clloooddxxxkkOO00XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc,....                                                             ....,cxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo'                                                                           'dXMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.                                                                             .cXMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.                                                                               .dWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                                                                                 cNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.                                                                                lWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                                                                               .OMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKKNWMMMNo.                                                                             .oNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l,..'l0WMMNd.                                                                           .dNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,      ,0MMMW0l'.                                                                     .'l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.      .dWMMMMWXkl;..             ..',;;;,.                 .,;;;,'..             ..;lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl        lNMMMMMMMMWX0kdlcc::ccloxk0KXNWWWNKxl;.          .;xKNWWWNXK0kxolcc::ccodk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc        :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.         cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,        ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWNXKKKXNNKx,          ;xKNNXKKKXNWMMMMMMMMMMMMMMMMMMMMMMMMMX:        ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXx:,.....''.              .''.....,:xXMMMMMMMMMMMMMMMMMMMMMMMX:        :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNo.                                  .oNMMMMMMMMMMMMMMMMMMMMMMX:        :XMMMMMMMMMMMMMMNK0kxdollcccclodxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNo.                                  .oNMMMMMMMMMMMMMMMMMMMMMMNc        :XMMMMMMMMMMNOd:,..               ..,:okXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNkl:::;:;;,.              .,;;:::cclxXMMMMMMMMMMMMMMMMMMMMMMMNc        cNMMMMMMMWKo,.                         .'l0WMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWWWWWWNKx'          'xXNWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc        cNMMMMMMXd.                               .dNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMX:          :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc        cNMMMMMK:.                                 .cXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNk:.          .:ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc        cNMMMMK:                                    .cXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWNXXK000000Oxl,.              .,ldk000KKKXXXNWMMMMMMMMMMMMMMMMMMMNl        cNMMMWd.                                     .xWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWOo:,'........                        ........'';lOWMMMMMMMMMMMMMMMMNl        cNMMMX:                                       lNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMO'                                                'OMMMMMMMMMMMMMMMMNl        cNMMMNo.                                     .dWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMK:.                                              .:KMMMMMMMMMMMMMMMMNl        lNMMMMXl.                                   .oNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMXkoc:;;;;;:cllc'                  ':lcc;;,,;;:cokXMMMMMMMMMMMMMMMMMNl       .oWMMMMMNk;.                               .;OWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWWWWWWWMMMWXl.              .lXWMMMWWWWWWWMMMMMMMMMMMMMMMMMMMMMNl       .oWMMMMMMMNk:.                          .'ckNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMXo.              .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl       .oWMMMMMMMMMWKkoc;,..             ..';cokXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWWWNKOo,.                 ,okKNWWMMMMMMMMMMMMMMMMMMMMMMMMMMWl       .oWMMMMMMMMMMMMMMWNX0kl'      .,ok0XNWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMNKOkddoolllccc::;;'..                      ..';;:ccclllloodxkOKNMMMMMMMMMMWo.      .oWMMMMMMMMMMMMMMMMMMMMKc.   .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    NOl,..                                                          ..;lONMMMMMMMWo.      .oWMMMMMMMMMMMMMMMMMMMMM0'   ,0MMMMMMMMMMMMMMMMWXOxkKNMMMMMMMMMM    //
//    :.                                                                  .cKMMMMMMWo.      .oWMMMMMMMMMMMMMMMMMMMMMK,   ;KMMMMMMMMMMMMMMMWk,.  .:OWMMMMMMMM    //
//                                                                         .dWMMMMMWo.      .oWMMMMMMMMMMMMMMMMMMMMMK,   ;XMMMMMMMMMMMMMMM0,      :XMMMMMMMM    //
//    .                                                                    .xWMMMMMWo.      .oWMMMMMMMMMMMMMMMMMMMMMK;   ;XMMMMMMMMMMMMMMMO.      ,KMMMMMMMM    //
//    :                                                                    :XMMMMMMWo.      .oWMMMMMMMMMMMMMMMMMMMMMK;   ;XMMMMMMMMMMMMMMMK;      '0MMMMMMMM    //
//    Kc.                                                                .cKMMMMMMMWo.      .oWMMMMMMMMMMMMMMMMMMMMMK;   ;XMMMMMMMMMMMMMMMNc      .kMMMMMMMM    //
//    MNOc'.                                                          .'cONMMMMMMMMWo.      .oWMMMMMMMMMMMMMMMMMMMMMK;   ;KMMMMMMMMMMMMMMMX:      .oNMMMMMMM    //
//    MMMWXOdlc;;,;;;::cccccc:'.                   .;ccllccc::;;;;;cldOXWMMMMMMMMMMNc        cXMMMMMMMMMMMMMMMMMMMMMK;   ;KMMMMMMMMMMMMMMWx.       .dNMMMMMM    //
//    MMMMMMMMMWWWWWWWMMMMMMMWXl.                .cKWMMMMMMMMWWWWWWMMMMMMMMMMMMMMMWk.        .xWMMMMMMMMMMMMMMMMMMMMK,   ;KMMMMMMMMMMMMMWk'         .;kNMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNo.                .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKx.          .dNMMMMMMMMMMMMMMMMMMWx.   .kMMMMMMMMMMMMNd.            .oNMMM    //
//    MMMMMMMMMMMMMMMMMMMWX0kd:.                  .:dO0XWMMMMMMMMMMMMMMMMMMMMMXx;..            .;xXMMMMMMMMMMMMMMMWk'     ,OWMMMMMMMMMMk.              ;KMMM    //
//    MMMMMMMMMMMMMMMMNOl;..                          ..;lONMMMMMMMMMMMMMMMMWk;.                 .;kWMMMMMMMMMMMMNd.       'xNMMMMMMMMMO'             .oNMMM    //
//    MMMMMMMMMMMMMMMWx.                                  .xWMMMMMMMMMMMMMMMNo..                  .oNMMMMMMMMMMMNo.         .dWMMMMMMMMW0o,..       .,xNMMMM    //
//    MMMMMMMMMMMMMMMMXOdllllllllllllllllllllllllooodddxxk0NMMMMMMMMMMMMMMMMMWKOkkkxxddoooollllldkKNMMMMMMMMMMMMWOollllllllloOWMMMMMMMMMMMNX0kxdlloxONMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    NXXXXXXXXXXXXXXXXXXXXXXXXXNMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXXNWMMMMMMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNWMMMMMMMMMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNW    //
//    ,'''''''''''''''''''''''''lXWx,''''''''''''''''''''''''''''':kNMMXxc,'''''''''''''''''''''''''''''''''''',cdKWMMMMNkl;'''''''''''''''''''''''''''''',k    //
//    .                         :XWo.                              'OWO;.                                         'xWMW0;.                                .d    //
//    .          ...............cXWo.       ...........            .kK;           .......................          '0MK;      .............................x    //
//    .        .l00K00KKKKKKKKKKXWWo.      c0KKKKKKKKK0d.          .k0'         :xO0KKKKKKKKKKKKKKKKKKK00l.        .kM0'     ;OKKK0KKKKKKKKKKKKKKKKKKKKKK0KN    //
//    .        .;dxxxxxxxxxxxxxx0WWo.      ;dxxxxxxxxxxc.          .k0'         ,loxxxxxxxxxxxxxxxxxxxxxd;.        .kM0'     cNMNOxxxxxxxxxxxxxxxxxxxxxxxxkK    //
//    .                         :XWo.                              .k0'                                            .kM0'     cNMO'                        .d    //
//    .                         ;XWo.                             .cK0'                                            .kM0'     cNMO'                        .d    //
//    .                         ;XWo.                      .;dxxxx0NM0'                                            .kM0'     cNMO'                        .d    //
//    .                         ;XWo.                       'OWMMMMMM0'                                            .kM0'     cNMO'                        .d    //
//    .                         ;XWo.                        'kWMMMMM0'                                            .kM0'     cNMO'                        .d    //
//    .                         ;XWo.                         .xNMMMM0'                                            .kM0'     cNMO'                        .d    //
//    .                         ;XWo.      ,,                  .dNMMM0'                                            .kM0'     cNMKo;::;;:;'.               .d    //
//    .                         ;XWo.     .o0c.                 .lXMM0'                                            .kM0'     cNMWWWWWWWWWO,               .d    //
//    .                         :XWo.     .oWXl.                 .cXM0'                                            .kM0'     .;::::::::::,.               .d    //
//    .          ,xkkkkkkkkkkkkk0WWo.     .oWMXo.                 .:K0,                                            .OM0'                                  .x    //
//    .          cNMMMMMMMMMMMMMMMWo.     .oWMMNd.                  ;Od.                                          .oNM0'                                 .cX    //
//    .         .lNMMMMMMMMMMMMMMMWd.     .dWMMMWx.                 .;OOc'.                                    ..:kNMM0,                             ...:xNM    //
//    OkkkkkkkkkOKWMMMMMMMMMMMMMMMMXOkkkkkOXMMMMMWKkkkkkkkkkkkkkkkkkkOXMWX0OkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkO0XWMMMMN0kkkkOkkkkkkkkkkkkkkkkkkkkkkkOO0XWMMM    //
//    dddddkXMMMMMMMMMMMMMMMMMMW0xddddddddddddddddddddddddddddddddddddddONMMXkdddddddddddddddddd0WMMNkdddddd0WWOdddddddddddddddddddddddddddddddddddddddxOXWM    //
//    .    .kMMMMMMMMMMMMMMMMMNo.                                       .:KMO'                  .xNM0'      lWX:                                        .'l0    //
//    .    .kMMMMMMMMMMMMMMMMMK;                                         .kMO'                   .oX0'      lNX:                                           '    //
//    .    .kMMMMMMMMMMMMMMMMMK;         .:ccccccccccccccccccc,.         .kMO'                    .co'      lNX:           ,ccccccccccccccccccccc,.             //
//    .    .kMMMMMMMMMMMMMMMMMK;        .lXWWWWWWWWWWWWWWWWWWNk'         .kMO'                      .       lNX:          .xNWWWWWWWWWWWWWWWWWWWNk'             //
//    .    .;ooooooooooooood0MK;         .',,,,,,,,,,,,,,,,,,,.          .kMO'                              lNX:           .,,,,,,,,,,,,,,,,,,;,,.              //
//    .                    .dWK;                                         .kMO'                              lNX:                                                //
//    .                    .dWK;                                         .kMO'                              lNX:                                                //
//    .                    .dWK;                                         .kMO'                              lNX:                                                //
//    .                    .dWK;                                         .kMO'                              lNX:                                                //
//    .                    .dWK;                                         .kMO'                              lNX:                                                //
//    .                    .dWK;                                         .kMO'                              lNX:                                                //
//    .                    .dWK;                                         .kMO'              ..              lNX:                                                //
//    .                    .dWK;                                         .kMO'              'xc.            lNX:                                                //
//    .                    .dWK;          .';;;;;;;;;;;;;;;;;,.          .kMO'              ,0No.           lNX:                                                //
//    .                    .dWK;          'kWWWWWWWWWWWWWWWWWK:          .kMO'              ,0MNd.          lNX:                                           .    //
//    .                    .dWK;          'OMMMMMMMMMMMMMMMMMX:          .kMO'              ,0MMWk'         lNX:                                          'x    //
//    .                    .dWK;          'OMMMMMMMMMMMMMMMMMX:          .kMO'              ,0MMMWx.        lNX:                                        .c0W    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HHF is ERC721Creator {
    constructor() ERC721Creator("Hoppy Holiday Frogs!", "HHF") {}
}