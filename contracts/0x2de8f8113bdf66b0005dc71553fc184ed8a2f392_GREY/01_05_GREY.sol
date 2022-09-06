// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GREYDOLL
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                      ..:~~?Y?~::.                                                    //
//                                                .:^!?Y5GG#&&&#B55PJ~:::^~~.                                           //
//                                             :!?5GB######BGGBGGGB#&#GP5Y5Y:                                           //
//                                          :7YG##&&#####BY?5GB########BGGGP?^                                          //
//                                       .^JG#&&&#####BBPPPGB#&&########P5G##G~.                                        //
//                                     .~YB&&########BB##B####&###&######BG##&#J^.                                      //
//                                   .:?B##############&##########B#&#######BB##BY~:.                                   //
//                                  ^JG#########################BBB#&##B#####BGB#BY!:.                                  //
//                               .:JG#######BBBBB#######&&&&&###B###BGGGB####BBBB#P!~^.                                 //
//                              .~5BBB###&#BGB###################GY7!75Y5PB#######BY7!~^.                               //
//                            .!YPGGPB######################BG5J7^:::^777?YB&&&####GY?7~:                               //
//                           :75GGPGB##############&##&#BG5?!~^^::::::^~!!?YB#&####GYY?!^:                              //
//                           .75PPPG###GBBBBB###&&###BG5?7!~^^^^^^^^^^^^~~!?YG####BBG5J7~^                              //
//                            .?PPGGBBPYY5G#####BPJ?JJ7~~^^^^:^::^^^~~!!77?YY5B#B##BBGPJ!~:.                            //
//                           .:J5PP55Y55P#&&#BPJ7!!!~~^^^^::^^^~7JY5GBB############BBBP5J7^                             //
//                           .!57^^^?G####BB5J5PPP55555YJ?!~^^7Y#&#BGP555GBBPG##BBBBGGPPY7~.                            //
//                           :JGY::~YBBGYJY5G##&&&#&&&##&&#Y!!5##BPY?J555YJ!!?GPPG#BGGGG5J!:                            //
//                          .!P##J~!YJ?7!!?5####BGGBB#G5PPY7!!?PBBGB#&###BGPYY5Y5G##BBGGPY7^                            //
//                         .~GB##GYJJ?77!!~JPB########BPYYYJ?JJYB#B5GB###B##GJJ5PP##BBBBGPY~                            //
//                         .7GBB##PYPGJ77~^^~?P#####&###5JYYYY5P##Y~~YBB#BP5J7J5PG##BBBBBBP~                            //
//                         .JB#BG#P5BGYYP!^^^~JGBBBGGGBGPY?JY5B###G??7YPY?~^~?YY5GB#BBBGP5Y~                            //
//                        .:5B#BPBBGBY?5B7^^^~!?JJ?7!77????JYJYYPBG5?~~^::^^~7??YPB##BBGPJ7~                            //
//                        .~G##BGBBGGYJ5J~^^^^^^^^^^^~~!!?7?PB#BPYBG!^::::^~77??JPB##BBBGJ!^                            //
//                        .:5######BGY?5?~^^^^^^^^^^:^^^:^!?PGPY7!77~^^::^~!?JJJYPBBBBBBGPJ^                            //
//                        ..JB#####BPY?Y?^^::::^:^::^^^:::^^^~~^^~~^:^^^~~~7?YYJYPBBBBBBGG5!                            //
//                        ..JB#BGB##G5J57::~!!::::::^::::^~7?YJ?YY55J!^~~~!7?JJ5YPBBBBBBPY?~                            //
//                        .:JB#GJYBBB5JP7^^YBBY!^::::::^^^?B&&&&&&#G57~^~~7YGGJ?YPPBBBBGPJ!:                            //
//                        .^YG#BPBBBB5YGY!~^!JB#GJ~::::^!~!?Y55PPJ!~^:^^~JG##BJ?JPGBBBBGPY7:                            //
//                        .~YGBPB##BBG5B5??77~~?P#B5?~^^^^~!~~~~~^~~^^^?P##PYYJYY5GBBBBGGJ7:                            //
//                        .!PBGJG#GPBBPBP55YPPJ::!YB#BPYJ7!!!~~!^^~~^!YB&#BY!7?PPPGGBBBGPY7:                            //
//                        .!5GG!?#GGBP5BGPBPPGP!::.:!P##BPYY55?~^^^~JG##G?!~!?!5BBGGGBBGP?~.                            //
//                        .!5GG77#GBBP5GG5GGGGP5JY!. .!YJJ?J5PP?!!~!?Y?JJJYYJY?5GBBGPGBGPY~.                            //
//                        .~5BB?YGGBBG5PG5P#BGPPPPY7:.:^^^^!!!7!!!!~~^^7PGGPPGPGGBBGPGGG5?!.                            //
//                        .~5BBJGGGB#G5PGY5BBBGGPGPPY7^^^~~?Y?!~^!!!!!7JGGPPPPPGGGGGGGGG577:.                           //
//                        .!YBBJ?PGBBBP5G55BBGGPPP5YJ?~^~!!7??7!~7~~~~7PPPPP5J5GGPGGPGGGPJ^.                            //
//                        .!Y5PJ!5B##BP5BP5BBBGGGG5J!^.:^!!7YY?!~~!~^^~5PPPP5JPPGGGGGGGGPY~.                            //
//                        .!J5G5YPGB#G55GP5BBBBBGG7:.::^~!!!7?7!^^^^^::J5PPG5Y5PGPPGGGPGG57.                            //
//                        .7YPGBBPGBBP555JYBBBBBPY7::^^^~~~~!!~^^^^^^^^~?PPPGYYPBGGGBGGGPY7:.                           //
//                        .?JPGGGGGGBBP5Y7JBPJYPJ^^^^^^^^^^^~^^^^:::^:^^~!~?P55PPPGGGBGGP5J!:                           //
//                        .?Y5JPBPGB##GP5YPP~^^^^^::::::^^^~~~~~^^:::^^^^~~?YY55G55PPGGG5JYJ^                           //
//                       .:J5GYPGPBBBBGPGBBJ^^:::..:^^^^^^^^~!!~~~^^:^^^^~!?5?5PGGPPPPGP5???!                           //
//                        ^Y5PGGGPG##BGPG#B7^^::::::.::^^^^^~~~~~^^^^:^^~^~!?!YPGP?JPPGP5?7~:                           //
//                       .!5PPP5BPG###BPPBG!^^:.::...:^^^^~~~~~^^^^^^^^^~!~^^~7Y5PYY5PPPPY^.                            //
//                       ^Y5PPY5BPPB##BGP5Y~::::::..:^^^^^~^^~~~~^^^^^^^~~~^^^!JPGPPGGGGGP!.                            //
//                       ~Y5GPPPBG5B#BBG5J!^::::::::.:^^^^^^~~~~~^^^^^^~~~~~~^!7YY5PGGGGG5!.                            //
//                      .!PGBP55GBGB##B5J?7~^^::::::.:~^~~^~~^~~~^^~~~~!~^~~^^~~~~!!?5Y5Y~..                            //
//                      .!GG5YYYPBBBBBGY??!^^^^^::::.:^^^^^~~~~~~~~~~~~~^^^^^^^^^^^~!JJ5J^...                           //
//                       ~55!:?Y5BBBBBPJJ?!~^::^^::^::^^^^~~~~^^^^~~~~~~~^^^^^^^^^^!J5P5J:..                            //
//                       ~JY?:!JP#BBBBG5J7~~^^^^^^^^^~^^^^^^^^~~~~~^^~~~~~~^^^::::::^?G5Y:..                            //
//                       ^JYY775PGGBBBPJ!~~~^^::^^^^~~~^^^^^^^^^~~~^^^~~~~~~^^:::^::^!J?5^.                             //
//                       :JYJ?JPPPPB#G?^^^~~~^^^^^^^~~~^^^^^^^^^~~^^^^~~~^~^^::::^:^~!J?Y7.                             //
//                       .?Y7~55J7?GB5!^^:^~~~~^~^~~~~~^^^^::^^^^^^^^~~!~~~^:::::^^^^~?JJJ^..                           //
//                       .?Y7.:::!!??!^^^^:^^^::~^^^^^^^~^^^^^~~^^^^^^~~~~^^^:::::::::~??J^..                           //
//                       .?J7.  :~^:^::~~~~^^^:.^~~~~^~~^^^^^~~~~^^^:^^^~!^:^:::::...::~~^:..                           //
//                       .77?~.   .::::^~~~~~~^^^~~~~~^^^^^^^^^^~^^^^:^^^^^:^::^:::::::::.:.                            //
//                        ^: .     .:::^^~~~~~~~~~~~~~^^^^^^^::^^^^^^^^^^^^^^:^^^::::::::.:...                          //
//                                ....:^^~~~~~~~~~^~~~~^^:^^::^^^^:^::^^^^^::::^^::...:::::...                          //
//                                ....:::^^^^^^^~~~~~~~~^^^^^^^^~^^^^^~~~~^:::::::.....::::...                          //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GREY is ERC721Creator {
    constructor() ERC721Creator("GREYDOLL", "GREY") {}
}