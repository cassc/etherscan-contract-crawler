// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MADHOUSE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                            .....         .;;','.         .....'.                                           //
//                          .:ooxKOc       'xO0XWK;        .,ddxXNo.                                          //
//                          .xXNWMWx.      ,0WWWMX:        .lKXNMMx.              .'cllcc:'                   //
//                          .dWMMMWk.      'OWMMMNc        .kWMMMMx.             .:kXXNWWWNOl,                //
//                           oNMMMWk.      'OMMMMNl        'kWMMMMx.            .:OKKNMMMMMMMNd.              //
//                          .dNMMMWO;......:KMMMMNd,,'....,cOWMMMMO:;cccccccoxkOOOXXXWWNWWMMMMW0,             //
//              .,;:loddxkdxOXWMMMWNXXKOO00XWMMMMMWNNNXXKXXNWMMMMMWNNWWWWWWWWWMMWWWWWXkldKWMMMMWd.            //
//           .'l0NNNWWWWWWWWWMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMWMMWWMMMMMMMMMWKdc;,,dNWMMMWx.            //
//           .c0WWMMMMMMMWMMWMMMMMMMWWWNNNNWWMMMMWNNNNWNNNNXNWMMMMN0OOOkO0KKNWMMMM0:.  .'kNNWMMNx,.           //
//           .dXWMMMMN0OOOk0KXWMMMMXxollcllxXWMMWNxcolooccllkNMMMMO;,,'',;:ckWMMMMk.   .oXX0NMW0l,.           //
//           .:0WMMMM0:....';dNWMMWO,..  ..cXMMMMNl........'oNMMMMx.      ..lXWMMMNd,;oONWKKWNOl;,.           //
//            .dNMMMMNl     .dWMMMMk.      :XMMMMNc        .lNMMMMx.        ,xNWMMMWWWMMMMMMXd:;,.            //
//             ,OWMMMMX:    .lKNWN0c.      ,ONWWWK;         oWWMMMx.        .;xNWMMWMMMMMMWKo;;,'.            //
//              ,0WMMMMK;    .oO0kl,        ,x00O:          cNMMMMO'         .:kKXWWWWWWXXOo:;,..             //
//               cXMMMMMK;   .,:;;;'         ....           cNMWWWX;          .;:ldddddlcc:;,'.               //
//               .dWMMMMM0:.  .',,..                        ,KWNX0o.           ..',,,,,,,,,'..                //
//                'kNMMMMMK;   ...                          .cdlc:.                ........                   //
//                 'xNMMMMWk.                                 ...                                             //
//                  .dNWWMMNc                                                                                 //
//                   'OWWWXk,                                                                                 //
//                   .lKOxo:,.                                                                                //
//                    .::,;,,.                                                                                //
//                     .,,,'.                                                                                 //
//                      ...                                                                                   //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MADHOUSE is ERC721Creator {
    constructor() ERC721Creator("MADHOUSE", "MADHOUSE") {}
}