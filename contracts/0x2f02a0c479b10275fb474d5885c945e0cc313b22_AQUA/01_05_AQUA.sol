// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AQUARIUM
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                .....         .;;','.         .....'.                                                 //
//                              .:ooxKOc       'xO0XWK;        .,ddxXNo.                                                //
//                              .xXNWMWx.      ,0WWWMX:        .lKXNMMx.              .'cllcc:'                         //
//                              .dWMMMWk.      'OWMMMNc        .kWMMMMx.             .:kXXNWWWNOl,                      //
//                               oNMMMWk.      'OMMMMNl        'kWMMMMx.            .:OKKNMMM∞MMMNd.                    //
//                              .dNMMMWO;......:KMMMMNd,,'....,cOWMMMMO:;cccccccoxkOOOXXXW.  WWMMMMW0,                  //
//                  .,;:loddxkdxOXWMMMWNXXKOO00XWMMMMMWNNNXXKXXNWMMMMMWNNWWWWWWWWWMMWWWW.    KWMMMMWd.                  //
//               .'l0NNNWWWWWWWWWMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMK-ARTMMWMMWWMMMMMMMMMW.     ,dNWMMMWx.                 //
//               .c0WWMMMMMMMWMMTHE-KEYMWWWNNNNWWMMMMWNNNNWNNNNXNWMMMMN0OOOkO0KKNWMMMM0:    'kNNWMMNx,.                 //
//               .dXWMMMMN0OOOk0KXWMMMMXxollcllxXWMMWNxcolooccllkNMMMMO;,,'',;:ckWMMMMk.   .oXX0NMW0l,.                 //
//               .:0WMMMM0:....';dNWMMWO,..  ..cXMMMMNl........'oNMMMMx.      ..lXWMMMNd,;oONWKKWNOl;,.                 //
//                .dNMMMMNl     .dWMMMMk.      :XMMMMNc        .lNMMMMx.        ,xNWMMMWWWMMMMMMXd:;,.                  //
//                 ,OWMMMMX:    .lKNWN0c.      ,ONWWWK;         oWWMMMx.        .;xNWMMWMMMM69MWKo;;,'.                 //
//                  ,0WMMMMK;    .oO0kl,        ,x00O:          cNMMMMO'         .:kKXWWWWWWXXOo:;,..                   //
//                   cXMMMMMK;   .,:;;;'         ....           cNMWWWX;          .;:ldddddlcc:;,'.                     //
//                   .dWMMMMM0:.  .',,..                        ,KWNX0o.           ..',,,,,,,,,'..                      //
//                    'kNAQUAMK;   ...                          .cdlc:.                ........                         //
//                     'xNMMMMWk.                                 ...                                                   //
//                      .dNWWMMNc                                                                                       //
//                       'OWWWXk,                                                                                       //
//                       .lKOxo:,.                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AQUA is ERC1155Creator {
    constructor() ERC1155Creator("AQUARIUM", "AQUA") {}
}