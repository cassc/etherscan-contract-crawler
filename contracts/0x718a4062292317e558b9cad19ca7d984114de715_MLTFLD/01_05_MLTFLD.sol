// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Multifold
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//    ~!!77??JJYYYYYYYYYYYJ?!^.                        ....^~~~!!777??J?7~.               //
//    ########BGPPPPPGGGGGGGGGPY7^::..        .:^~!?JY5YJ!5BBBB#BBBB#B5J?5P~              //
//    #####BGP5PPPPPPGGPPPGGGGGBBBGGGGP5YYYY555PPGGBBBG5PGGGBBPYJGBB#J~~~~?G              //
//    BBBBGP5PPPPPGPPPPPPPPPPPPGGGGGGGGPP555PGGGBBBBBGP5YYJP#?~~~~Y##57~~!Y#J7~:          //
//    PGGP5PPPPP55555PPGGGP5555PGGP5YJJY5PGB####BP5YJJY5PGB#B7~~~~Y&&#BPPBB#5JJ5!         //
//    555PPPPP55PGGBBBGP55PGBBGP5YY5PGB######G5Y?^5GGBB###&&&#PJ5GP~^^^!JG#G~~~7P         //
//    PP5PPPPGB&&#BP5PGB###GP555GB###&&&&#GP55PG??G##&&&@&&#BG#57~.      .J#GJY5~         //
//    BG5PPPGGGBGGGB#&&#BP55PB####&&@&#BBGGBB####&&&@@&#BBB7!~7P.          J&#B5J~        //
//    &B5PPGGB####&&&#BGPGB##&&&@@&##BBBB####&&&@@@&#BBBB#B?!!7G:          ^B?~~7P^       //
//    @#5PGGB&@@@@&#BBBB##&&&@@@&#BBB####&&&@@&&&#BBBB###&&&GBG7           Y#J!!7G^       //
//    @&GGGGGB#&&BBB##&&&&@@@&#BBBB##&&&&&@&##BB#5JB&&&&@@&&#PJJ5~        ?&@&B5Y~        //
//    @@#PPGGPGBBB##&&&&@@&##BBB##&&&&&&&&##BB###[email protected]@&&##B#P~!!?G^:^::~7P#PJJ#G.         //
//    @@@BPPGG#&&&&@@@@&&###B##&&&&&&&&######&&&&@&&&##BBB##BY?JP##B55B##&7...^GP         //
//    @@@@#GPPG&@@@@@@&##&&#&&&@&&@@@&&&&&&@@&&&&&####G#&&&&&&####?:..~P&&7::::P5         //
//    @@@@@&BGPGB&&@@@@@@@&&&&&&@&5!J5PGPPY?!^!JPGB###GPPPG#&#####^....5GJGPJYPJ.         //
//    @@@@@@@@#[email protected]@@@@@@@@&GJ^               .::^::.   ^7JG##&G?~7YG^ .^!~:           //
//    !7??JJY55PP5555B####BPY!^                               .^!?JYJJ7.                  //
//                   ....                                                                 //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract MLTFLD is ERC721Creator {
    constructor() ERC721Creator("Multifold", "MLTFLD") {}
}