// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SUBSTANCE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~!!!~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!~~~~!!!~~~~~!!!!!!!!!!!!!!!!~75GBBP7~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!~!7J5PGGGP5YJ?7!~~~~~~!!!!!!!~Y##BB#&J~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!~!JG###BBBBB####BGP5YJ?77!!!!~~?##BB##5~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!~7G##BBGGBBBGGBBBBBB#####BBGGGP5B##B##B5YYY5YYYJJJ??77!!~~~~~!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!~?B#BBGBBBBBBBBBBBBBGGBBBBBBBBBBBBBBBBBB##############BBGP5Y?7!~~~!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!G#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGBBBBBBBBBBB###BGPY?7~~!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!~J##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGBBBBB##BPJ!~!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!~J##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGBBB##BY!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!7B#BGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##5!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!~J##BGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGB##?~!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!~JB##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##G7!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!~!JGB#BBBBBBBBBBBBBGGGGGGGGBBBBBBBGGGGGGGGBBBBBBBBBBBBBBBBBB##BBBGG5?!~!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!~~?###BBB#######BBBBBBBBBBBBBBBBBBBBBBBBBBBB#######BBBBBBB##B7!!!~~!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!~?##BGBBBBBBBBBBBBBBBBB#######BBBBBBBBBBBBBBBBBBBBBBGGGGGB##Y~!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!~P###BBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBB#######Y~!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!~?##PPGBBB###########BBBBBBBBB################BBBGGGP55YJG#G!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!P#P~~~!!!77??JJJJYY55PPPGGPPP55555YYYJJJJ??77!!!~~~~~~~^?##?~!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!~Y#B!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!B#5~!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!B#5~~~~~~~!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~G#G!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!~~~~~Y##7~~~?5GBGBGPJ~~~~~~~~~~~~~~~~~?YPGGGPY7~~~~~~~~~~~~~~~~~P#B!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!7?JJ??B#5~~JB#GGGBPY#&5~~~!777!~~~~~~JB#BGGB5P&#?~~~~~~!!7777!~~~P#B7!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!~?PPGGG##?^Y##J5##G55##J~!5B###BP7~~~5##JP##GYP&#?~~~~~7GGGGGGJ~~~B#G!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!~!!77Y##7^5&#JJPGGGGY7~!G##P!~Y##Y~~G&B75GBGBGY7~~~~~~~77!!~~~~^?##Y~!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!7PBBGG##?^~JG#BPPPPGP!~!B##5JJY#&5~~75B#G555PPY~~~~~~~7PGGGGP7^7B#G!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!77!!!P&B!^~~7J5555Y?~~~!?Y5PP5Y?~~~~~!?5PPPP5J~~~~~~~~~!!!77~!G&B7~!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!~!!~!5#BJ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~YB&G7~!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!~JB&G?~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~?G&BY!~!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!~!YB#GJ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!JG#B57~!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!~!JG#GJ!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~?5B##B?~~!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!~75B##BPJ!~~~~~~~~~~~~~~~~~~~~~~~~~~~~!7J5G##BB##P!!~~!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!~7B##B####BY7!~~~~~~~~~~~~~~~~~~~~!?YPBB#BBBGP55GB#BGY?!~~!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!~Y##BPPPPGGB#BPJ7~~~~~~~~~~~~~7YPB###BP55Y5PPGGGGB#####B5?!~!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!~!B##GGP55Y55PG###G?^~~~~~~~~?B##GPPPPPP555PPGGB###BGP5PB##G?!~!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!~7P####BGPPPPPPG####B??7!!!!7?####G5Y5PPGGGPGBB##BGGGGGPPPGB##GJ!~!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!~JB#BGPGB#BBGGG##BP###BBBBBBBB###BB##P5PPGGB###BG555PPPPP555PGB##P7~!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!~Y##BPPP55G###B##G5P##GY55555555B#B5G##BGG###GGPPP5YY5PPPP5YYY5PPB#B7~!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!~Y##BGGGPPPGGGBBBGPPB##5YYYYYYYYYB##PPG####BGPPPGGGGPPPPGGGGPPP5PGGB#B7~!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!~J##BPPP5555PPPP55555B##5YYYYYYYYYG##P55PGGGP555G##GGPPPPPGGGGPPPPGGG##B!~!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!~7B#BPPP5P##PPPPPYYYY5B#B5YYYYYYYYYG##55BBPPP5YYYP##GPP5YY5PPPP55555PPG##P~!!!!!!!!    //
//    !!!!!!!!!!!!!!!!~7B##GPGP5G##GPPPP55555##BYYYYYYYYYYP##P5PGPPPP5555B#BPP55555PPPP5555PPPB##Y~!!!!!!!    //
//    !!!!!!!!!!!!!!!!!G##GGGGPPB##GGGGGPPPPG##PYYYYYYYYYYP##GPPPGGGGPPPPG##GGGPPPPGGGGGPPPPGGGB##J~!!!!!!    //
//    !!!!!!!!!!!!!!!~5##PPPPP55G##PPPPP5555G##5YYYYYYYYYYP##G5PGGPGP5555P##BPP55555PPPPP555PPPPB#B7~!!!!!    //
//    !!!!!!!!!!!!!!~?##GPPPPP55B##PPPPP5555B#B5YYYYYYYYYY5##GPB#BPPP55555B##GPP5555PPPGP5555PPPG##5~!!!!!    //
//    !!!!!!!!!!!!!!!P##5GGGGPPPB##GGGGGPPPP##BYYYYYYYYYYY5##BPPPGGGGPPPPPG##BGGPPPPPGGGGPPPPGGGGB##?~!!!!    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SUB is ERC721Creator {
    constructor() ERC721Creator("SUBSTANCE", "SUB") {}
}