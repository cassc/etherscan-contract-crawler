// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Milady Saga
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    ~~~!!!!!7777777777!!!!!!!!77?JJYY5YY?!~~^^^^^::::..::::::::^^::::::::::^^~!!7777777??7777!    //
//    ^^^^^^^^^~~!!!!!!!!!7?Y5PGGBBBBBBBBBBG7::::::::::::::::::^^^^^^^:::.::^~~~!!!7777777!!~~~~    //
//    ^^^^::::::.::::^!J5GBBBBBBBBBBBBBBBB##BJ....:::::::::::::::^^^^^::::::^~~^~!!7777!~~^^^^^^    //
//    :^^::::::.....~PBBBBBBBBBBBBBBBBB#######Y:.::^^:::::::::::::::::::::::^^^^^^^^^::^:::::^^~    //
//    ^^::::::::::.:G#BBBBBBBBBBBBBBBBBBBB#####G?777777777!!~~^^::......:::::::::..:::::::::^~~~    //
//    ^^^^^^^^^^^^:7PBBBBBBBBBBBBBBBBBBBBBB#####BJ777???????????77!~^:...::::::::::::::::^~~!!7!    //
//    ^^~~~~~~~~~~^Y?PBBBBBBBBBBBBBBBBBBBBBB###BB?777777777777777????7!!~^::::::::::::^~!!77777?    //
//    ^~~^^^^^^~~~^5!7BBBBBBBBBBBBBBBBBBBBBB##BP?!!!!!!!!!!!!777777777777777!^::::^^~~!!!!!~~~!!    //
//    ~~~~^^~^^^^~?G7~PBBBBBBBBBBBBBBBBBBB#BBPJ!~!!!!!!!~!!!!!!!!!!!!!!!!!!!77!!^^^^~~~~~^^^^^^^    //
//    ~~~~~^^~~^^!B#G?JBBBBBBBBBBBBBBBBBBGPY7~~~~!!!!!!!!!!!!!!!!!!7!!!!!!!!!!!!77!~^^^^^^^^^^^^    //
//    ~~~~~~~~~~^7BBG77YBBBBBBBBBBBBG5Y?7!!~!!!!!!!!!77777!!77777!777!!777777!7?7!77!^::^^^^^~~~    //
//    ~~~~~~~~~~~?BBG777?JY55YYYJ?7!!~~~~!7777777777777?777!!?777!7?77!7?7!777!?J7!!77^^^^^~~~!7    //
//    ~~~~~~~~~~!J#BG7!!!77!!7!7!!!!!!!!!7777!77777777777777!7?77!!7?7!!YJ7!77!?J?7!!?!~~!!!!!!~    //
//    ~~~~~~~~~~7JPPJ777?J?7??JJ?777!!777777!77777??77!^~777!!7!7!!~77!7J?7!!7!7J?7!777!!!!!!!!7    //
//    ~~~~~~~~~!777???77JJ??JJJJ?77!!77??777!7777!~!77~~~!77!!!~!!!~77~~~~!!~!7?J77777?!~~~~!!!!    //
//    ~~~~~~~~~777???77?JJ??JJJJ777!!77??7777777!~^~77~~~~!7!!~~~~~~!~~^^~~~~~~!77?77777~!!!!!!7    //
//    !!!~~~~~!777??777JJJ?JJJ?J777!77!~~!77!!!~~~~~~~~~~!!!!~~~~~~~~~^~!~~~^^^~!!??!77!~~!!!!!~    //
//    !~~~~~~~!7???777?JJJ?JJJ???77!7!~~~~~!~^^^~~~~~~~~~~~~~~~~~~~^^~~P#BGGP5J~^~77!7!~~~~~~~~~    //
//    ~~~~^^^^!???7777JJJJ?JJJ???77!7~^^^^~!?YPY~^^^~~~~~~~~~~~~~~^~777?JYYYY5P7~~!77!~~~~~~~~~~    //
//    ^^^^^^^:^?J?7777JJYJ?JJ?7?J77!!~!?YPGBBGP5?7!~~^^~~~~~~~~~~^!?~7YPGBBBGJ~7?!!!~~~~~~~~~~~~    //
//    :::::::::!J7JYJ??Y55JYP5J?7!~!7GBBGPYJ?777?JYY?!~^~~~^^^^^^~?~^?GBBBGB#BJ^7?~^^^^^^^^^^^^:    //
//    :::......^?JGBBPYPBBGBB##P?!~~75J7!~?JY5P55Y?7~~!7~~~!!!!!!77^?BBBP555B##J~?~::::::^:::^^^    //
//    ..........YGBBBBBBBBBBGPY?777??~^:^75PPY5GGGGPJ~^~??77!!!!!J!~G#BBG5GPB##5~??J7~^^^^^~7YY5    //
//    ..........?BBBGGP5YJ?!!~~^^^^7!^^7PGGP?775PPPGBY^^~?~^^^^^~?7!##GGBBB###B!!7YBGGP5YY5PBBBB    //
//    ....^~~^..^?J?7!~~~~~~~~~~~~^7!^?BBGGGGPGBGPPGGG~^^?~^^^^^~!J?#BBBB#BB##Y~?!PBBBBBBBBBBBBB    //
//    ..:?5P5Y?~~~~~~~~~~~~~~~~~~~~!7^J5BBGPPGGGGGGGGG7^~?~~~^^^~~!YB#B##BB#&5~777GBBBBBBBBBBBBB    //
//    ~7JPGGPPPJ!~~~~~~~~~~~~~~~~~~~?~^^JBBGPPPPGGPPPBJ^?!~~~~~~~!~!J5GBBB#&B777~YBBBBBBBBBBBBBB    //
//    PGGGGGPPPG5?!~~~~~~~~~~~~~~~~~~7!^:7PBGGGGGPGGB#P7!^~~~~~^^~!~~~!77?JJJ7!~7GBBBBBBBBBBBBBB    //
//    GGGGGGPPPGGG5?!~~~~~~~~~~~~~~~~~77~:^7GBGGP5YY5Y?~^~~~~~^^^^~~~~~~~~~~~~~!PBBBBBBBBBBBBBB#    //
//    GPPGGGGGGGGGGPP5J?7!~~~~~~~~~~~~~~7777JJ?77777!~^^~~~^^^^~~~~~~~~~!!~~~~!5BBBBBBBBGGGBBBBG    //
//    GGGGGGGGGGGPPPGGGGP5YJ?!!~~~~~~~~~~~~~~~!!~~~^^~~~~~~!~!!!!!!~~~~~!!~~~?5GBGGGGGGBGGBBBBBB    //
//    GGGGGGGGGPPPPGGGGGPPPGP5YYJJ7!!~~~~~~~~^^^~~~~~~~~~~~~~~~~~^^~~~~~~~!?5GGGGGGGGBBBBBBBBBBB    //
//    PGGGGGPPPPGGGGGGGGPPPPP555PPP55YJ?!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!7YPBGGGGGGGGGGGGBBBBBBBG    //
//    GGGGPPPPPGGGGGPPPPPP5PP55PPPPPPPPPP5YJ?7!~~~~~~~~~~~~~~~~~~~~!7?YPGGGGGGGGGGGGGGGGGGGGGGGB    //
//    GGGGGPGPPPPGPPGGGGGPPPPPPPPPPGGPPPPPPGGGP5YJ?!!!~~~~~!!!!7?JYPGGGGPPPPPGGGGGGGGGGGPGGGGGGP    //
//    PGGGGGGGGGGGPPGGGGGPPPPPPGGGGGGGGPGGGGPPPGGGY!77777!!!~~~5GGGGGGGGGGPPPPPPGGGGGGGGPPGPPPPG    //
//    PPPPPGGGGGGPPPPPPGGPP555PPGGPPPGGGGPYJ???YP57~~~~~~~^~~~!Y5J?JJY55PGGGPPGGGGPPGGGGGGPGPPPP    //
//    P55PPPPPPPPPGGPPPGPPPPPPPP55PPPY?7!~~~~!~~JYJ?777777!!!7JY!~~~~~~!7?5GGPGGGGGGGPPGGGPPP555    //
//    555PPPPPGGGGGPPPPGPPPPPPPP55PPJ~~~~~~~~!!~!JJYYYJ????JYYJ!~~!~~~!!!~~7YGGPPPGGGGGGPP55YY55    //
//    55555555P555YYY5PPPPGP5PPPPPP7~~!~~~~~~!!~~??77??JJJ??77!~~!!~~~!!!!!~~JP555PPPPPP55YYYY55    //
//    55YYY555555YYYY55PPGGPPPPPP57~~~!!~~~~~~!!~!?77!!!!!!777!~~!~~~!!!!!!!!!YP55PPPPPP55YY55PP    //
//    P55555555PP5PPPPPPPGGP5P5PPJ~!~~~!~~~~~~~!~~7?777!!77??!~~!~~~~!!!!!!!!!75P5PPPPPPPP555P5Y    //
//    P555P555555PPPPGPPP55YYJYP57!!!~~~!!!!!!77!~!?!~!7?7!7!~77777777777!~!!!!YGPPPGGGPPPPPPP55    //
//    PPPPPPPPPPPGGPPPP55YYYYJYYJ!!!!~~!????JJ?J?!~7!!JYJ?7!~!?J???JJJJJ?!~!!!!7PP5PGBBGGGGP55PG    //
//    GGGPGGPYJJJJ5PGGP5555YJJJJ7!!!!~~7???JJJ??J!~!??J?7??7~!JJJJJJJJJJJ!~!!!!!5PPPGBBBGBGGPPPP    //
//    GGGGY7~~~!7777?J5GGP5JJJJ?!!!!~~~???JJJ????7~!J7!7Y?~!~!????????JJJ?!!!!~~PBGGGGPPPGBGGPPB    //
//    PP57^^7?JYYJYJ!~!5GP5YYYYJ!!!!~~!7!!77!!!!!!~!Y?!~!~~7!~!!777!!!!777!!!!!~YGPJ7!77??J5GGGG    //
//    PGJ:^?5J!~~!7JJ~~~YJJJYJJ?!!~!!~!!~!!!!!~~!!~7GPY!~~77!~~!7777!!!!777!~^^^!J~^!?777??!7PGG    //
//    GG?^~Y5?:~!!~^~!!~~~~~~~~~~^.~~~~~~~~~~~~~~~^!Y?!!!~~~!!~~~!!!~~~~~!!~:::^^??!5!:.^?Y!^?PP    //
//    PPY~~7Y5Y?77~^7?!!!~~??!!!^:^^^:::::::::::::::::~~:.::::::::::::::::::::~!^!!7Y~^~^7J~:JGP    //
//    55YY7!!?JYJ?^^~!!7?7^~!!77^:~^^::::::::::::::::~~:..:::::::::::::::::::::::::^!7?J77~^75PB    //
//    PPPPP5JJJ?7^~!!!!!~!!!!!!!~!~~^^^~^^^^^^^^^^^~!!~~~^^^~~~~^^^^~^^^^^^~^^^^^~777????7?Y55PP    //
//    GPG5GPGG#BBBGPPPPGPGPGPGGJ777!!!!7!!!!!!!!~!??????777777??!!!777!!!!7?!!!!~?PPPBGBBPPPGPGB    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract prince is ERC1155Creator {
    constructor() ERC1155Creator("Milady Saga", "prince") {}
}