// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gio Karlo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@&@@@@@@@@@@@@@@@@@@@@@@&&&@@&&&&&@@@@@&&&&&&&&&&&&&&&&&&7            //
//    &&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@&&@@@@&&&&@@@@&&@@@@@@@&&@@@&&&&&@@@&@@@&&&&&&&&&&&&&&P             //
//    &&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@&&&&&@&&&&@@@@@@@@@@@@@@&&&&&@@@@@@&&&&&&&&&&&&&?              //
//    &&&&&&&&&&&&&&&&&&&&@@@@&&@@@@@@@@@@&&&&&&&#&&&&&&@@@@@&@@@@@@@&&&&&&&&@&@@&&&&&#&&&&&&&B.              //
//    &&&&&&&&&&&&&&&&&&&@@&&&&&&&&&@@@@@&&&&####B#&&&&@@@@@@@@@@@@&#&&&&&&&&&&&&&&&#G5GBBG#&B7^              //
//    &&&@@@&&&&&&&&&&&&&&&&&&&&&&@@@@@@&&&&##BBGGB&#&@@@@@&&@@&@&#GBBB#####BB###B##GY???7~7G:                //
//    &&@@@&&&&&&&&&&&&@&&&&&&&@@@@@@&&&&&&##BGGGPG##&@@@@&&&@&&&BGGGGGGGPPP55P5P5G5Y7!!!^:^.                 //
//    @@@@@@&&&&&&&&&&&&&&&&&@@@@@@&&&&&##BBGGGPPPGG#&@@@&&&&&&&#GPPPPP555YYYJJJYJ?77~~^^::^                  //
//    &&&@&&&&&&&&&&&&&&&&&&&@@@&@&&&&&#BBGGPPPPPPPPG&&@@&&##&@@#GPPPP55YYJJJ??7?7!!!~^^^^:^.                 //
//    &&@@@&&&&&&&&&&&&&&&@@@@@@&&&&#BBGGGPPPPPPPPPPGB&&@&&&B#&@&GPPPP55YYYJJ?77!!~~~^^^^^^^:                 //
//    &&@@@&&&&&&&&&&&&&&&&&&&&@&&##BGPPPPPPP5PPPPPPGGB#&@&#&BB&@#PPPP555YYJJ?77!!!~~~^^^^^^:                 //
//    &&@@&&&&&&&&&&&&&&&&&&&&&&#BBGGGPPPP55555PPPPPPGPGB&@&##BB#&&GPP55YYJJJ?777!!!~~~^^^^^^                 //
//    @@@&&&&&&&&&&&&&&&&&&&&&#BGPP5PPPPP5P555P5PPPPPPPPPG#&&#GBGGG#BGP5YJJ????77!!!~~~^^^::^                 //
//    @@&&&&&&&&&&&&&&&&&&&&&#GGPPPPPPPP555PPPPPPPPPPGGGGGGGB###BGPPPPGPYJ?????777!!~~^^^:::^.                //
//    &#BBB####&&&&&&&&&&&&##BGPPPPPPPPPP5555PPPPPPPPGGGBBBBBBBB##BBGGP55YJ?????77!!~~^^^^:^^:                //
//    B##B##BB##&&&&&&&&&#BBGGPPPPPPPP5PP555PPPPGGBB###&&&&&&&&&&&&&&###BBGPYYYYJYJ?????7??J57                //
//    &#BBB###BB#&&&&&&&#BGGPPPPPPPPP5555PPPPPGGB#########&&&&&&&&&@@&&&&&&#GPPPPPPGGBB####BG~                //
//    BGGBBB#&&BB#&&&&&#BGPPPPPPPPPP55555PPGGGBB##BBBBB#######&&&&&&&&&&&&&#BGPPPGB#&&&#BGP5^                 //
//    GGBBB#&&&#BBB&&&#BGPPPPPPPPP5P555PPGGGB######BBB#########&&&#########BG5JJ5GBBBPY?!~^                   //
//    GG#&&&&&#BBGB&&&#GPPP5PP5PPP5PPPPPPPGGGBBGGB##BGB&&&&BB#&&&&&#####BBBGY7~5##&&##GYJ5^                   //
//    BG&&&&###&#GG##BGPPP555PPPPPPPPPPPPPPPGGGGGGBBB#BBBGGGBB&&&&&###BBBGGPY~!#BB#&#P??J^                    //
//    BGB#&##&&&GPPGGGGGGPPPPPPPPPPPPPPPPPPGGGGGGGBBBBB#########&######BBGGPY!~B##BBGP5Y?                     //
//    BBBBB##&&#BGPPPPGGGGGPPPPPPPPPPPPPPPGGGGGGGGGGGBBBBBBBBBBBB#####BBBGGP5?^7Y5555YJ!~                     //
//    PBBBBGGGB#&#GPGPGGGGGGGPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGBBBBBBGGGGGPPJ~^~~!!7!~~^                     //
//    5PGBGGGGGBGGPPGPGGGGGGGPGGGPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPY!^^^^~~~~~^                     //
//    GGG&&BGGGGGGGGBGPGGGGGGGGGGGPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPP57^^^^^~~~~:                     //
//    GGG#&BGGGGGGBB##GGGGGGGGGGGGPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPP555?^^~~^~~~^                      //
//    GGGGGGGGGGGBBBBBBGGGGGGGGGGGGPPPPGPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPP55Y?~:~~~~~~                       //
//    GGGGGGGGGGGGGGGBBBBGGGGGGGGGGGGGGPGGGGGGGGGGGGGGGGGGPGPGGGGGBGGGPP55555Y?!:^~~~^                        //
//    GGGGGGGGGGGBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPGGGGGBBGP55555555Y?~^~~^                         //
//    GGGGGGGGGGGGBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPGGGBBGGGGGP55PPY!~~~.                         //
//    GGGGGGGGGGGGBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPGGGGGGGBBBGGGG5J7~^~~.                          //
//    GGGGGGGGGGGBBBBBBBBBBBGGGGGGGGGBBBGGGGGGGGGGGGGPPPPPPPPPGPPGGGGGGGGJ?Y7^:^^~:                           //
//    GGGGGGGGGGGBBBBBBBB##BBBGGGGGGGGGBGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPY!~7?^::~:                            //
//    GGGGGGGGGBBBBBBBBB#B#B#BBGGGGGGGGGGGGGGGGGGGGPPPPGGGGPPPPP5PPPGGGGP5YJJ7!~~.                            //
//    GGGGGGGBBBBBBBBBBB######BBBGGGGGGGGGGGGGGGGGGGBG5JJJJYY555PGBBBBBBBBBGP5J7^.                            //
//    GGGGGGGBBBBBBBBBBB#B######BBBGGGGGGGGGPGGGGGGG#&&#BG5J7!~~~~~~!!!!!!~~~^^::::::::::...                  //
//    BBBBGBBBBBBBBBBBBBB########BBBGGGGGGGGGGGGGGGGBB##&&&&&&#BG5J7!~^^^^^^^^^^^^^^^^^^^^^:::::...           //
//    GGBBBBBBBBBBBBB#BBBB########BBBBGGGGGGGGGGGGBBBBB#####&&&&&@&&&#BG5J7!~^^^^^^^^^^^^^^^^^^^^^^^:::...    //
//    BBBBBBBBBBBBBBBBBBBBB#B#######BBBGGGGGGGGBBBBBBBBBBBB####&&&&&&&&&&&&&#BG5J7!~^^^^^^^^^^^^^^^^^^^^^^    //
//    BBBBBBBBBBBBBBBBBBBBBBB#########BBBGGGGGGBBBBBBBBBBBB#####&&&&&&&#GY7?J5GB####BG5J7!~~~~~~~~~~^^^^^^    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBB########BBBBBBGBBBBBBBBBBBB####&&&#BBGP5J7!~~~~~!:.^!YPB#&&&&&&###########    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBB###########BBBBBBBBBBBBBBBB#######BG5J7777!!!~~~~        ..:::::::::::::::    //
//    BBBBBBBBBBBBBBBBBBBBBBBB#BB##############BBGGGGBBBBBBB#####BGPY?!??7!!!!~!:                             //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBB###########&&&###BBGGBBBBBB#####GGPJ77??77!!!!^                              //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBB############&&##&&####BB#######BBGPY?J??777!!~                               //
//    BBBBBBBBBBBBBBBBBBBBBBB###########&&&&&&B5YB##&&#####&&&&&##BPYJJ??77777!                               //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GK is ERC721Creator {
    constructor() ERC721Creator("Gio Karlo", "GK") {}
}