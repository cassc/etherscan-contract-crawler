// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cellscapes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~^^^^^^^^^^^^^^~~~~^^~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~^~^^^^^^^^^^^^^^^^^^^^^^^~^^^^^^^^^^^^^    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^~~^^^^^~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^~~~^~^~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~~    //
//    ^^^^~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~^^^^^^^^^^^^^^^^    //
//    ~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:^^^^^^^:^::^^::^^^^^^^^^^^^^^^^^^^^^^^^^^^:::::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::^::::    //
//    ~~~~~~~~^^^^^^^^^^^^^^^^:^^^^^^^^^^^^^~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::::::^^^:^^^:::^::^^^^^^^^^^^^^^^^^:::^^^^^:::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::::    //
//    ~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:^:::^^^^^^^^^:::::::::::^:::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:::^^^^^^^^::::::^^^    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:::::^^^^^^^^^^^^^^::^^^^^^^^^^^^^^^^^^^^^^^^^^^:::^^^^^^^^^^^^^^^^^^^^::^^::^^^^:^^^^^^^:::::::::^^^^:::^^^::::::^^^^:::::^^^^^    //
//    ~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:::^:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:^^::::^^^^^:::^^^^^^^^^^^^^^^^:::::::::^^^^^^^^^^:::::^:^^^^^^^^:^^^^^^^^^    //
//    ~~~^^^^^^^~~~~~~~~~!!!!!~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^::^:::^^^^^^^^^^^^^^^^:::^^^^:^::::::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:::^^^^^^^^^^^^^^^^^^^    //
//    ^^~~^~~~~~~~~~!!!?JJJJJJ????7~~~~~^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ~~~~!7777777!!JJJYYYJJYYJJYYJJ7!!~~~~~~^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:::::^^^    //
//    ~~!?YYYYYYJJ?YYYYYYYYYYYYYYYYYYYJ?7!~~~^^^^^^^^^^~~~!7????7!!!~~~~~~~~~~~~~~^^^^^^^^^~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:^^^^:^^^^^^^^^^^^~~~~~~~~~^^~!~~~~~^^^^~~~~!!!    //
//    ~7Y555555Y5YY55YYYYYYJ55YYY55YY5YYYJ?!~^^^^^^^^^^~!7JYYYYYYYJJ?77!~~~~~~~~~~~~~^~~!7?J?777!~~^^^^^^^^^^^^^^^^^^^~~!!7???77!!77!!~~^^~^^^^^^^^^^^^:::::::::::::^^^^^^^^~!77!77??777777!!!!!!~~^^^~!77??77    //
//    !J555555555555YYYYY5YJ55YY55555J?JYYJJ7~^^^^^^^~~~7JYYY55YY55YYYJ?7~~~~~~~~~~~~7JJYYYYJJJYJJ?7!~^^^^^^^^^^^^^^^~JYJJYY5555YYYYJJ?7!~~~~~~^^^^^^^^^^^^^^:::^^::^^^^^^^^~!!77????????????7777!!~^~!77!!?7?    //
//    Y55555P5555555555YY55555Y555555Y777JJJJ7!~~~~~~~~!!?YYJ?JJ55555YYJ?7!~~~~7J!~~7JYY55555YYYYYYJJ7!77!~^^^^^~~~^^~JJYY5YYYYYYYYYYYYY5J????7!^^^^^^^^^^^^^^::^::^^^^~~~~~!77???7!!!????JJJJJ????77777777???    //
//    YJYJJY5555555555555YY5555555555YJ?7?JJJJJJ???????????J?!755P5555YYJ?7!!!755J77?JY5YYYYYYYYYYJJJYYYYYJ7!^~7JJJ?JYYYY5YYY??JYYYYYYYYYYJJJJJ?7~~~^^^^^^^^^^^^^^:^~!7777777???????7?JJJJJJ??JJJJJ???????????    //
//    YYYYYYYY555555555555555555555Y?YJJJJJJJJJJJJJJJJJJ?JJ?????JY55555YYJ7!7?JYYYYY55555YYYYY5555Y5P5P55YYJJ~7JJ?JYYYYYY5YYYYYY5Y5Y5YYY5YYYYJJ?J?!~~~!!!!!~^^^^^^^~!!7???????JJJJJJJJYJYJ7???JYJJJJJJJJ??JJJJ    //
//    YYY5555555PP55PPP55P55PPP55555J5YYJJJJJJJJJJJJJJJJJJJJJJJJ??J555P555J?7?JJY5YYY55555555PPPPPPPP5555YYJ?7??JJ?77YYYY5555555555555555YY55YJJJ?7!7????JJJ7~^^^^~!77???????JJYJJYJYYYYYJJJJJYYJJJJYYJYJJJJJJ    //
//    YY5P55PP55PPPPPPGGPP5PPGG55555555YYJJYYJJJJJJJJJJJJJJJJJJJJ??YPPPP5YYYJJJYY555555555PPP5PPPPPPP5P555555YYYYY?7Y55555555555555555555Y5Y5YYYJYJYJJJJJJYYJ?7^^^~!77777??JJJY5YYYY5Y5YYYYYY5YYYYYYYYJJYYYYYJ    //
//    55PPP55P5PPPPPPGGGGPPPPBB5YYY555555YYYYJJJJJJJYYJJJJJJJJJJJJJJPGGGPPGGGPP5555555555P5555555PPP55555PPG5Y55555555555555555555555555555555555YYYYYYY5YYYJJ7~!!77777!7???JJJJYJJY5YYJYYYYYYYYYY??JJJJYYY5YY    //
//    55PPP55P5PPGGGGBGGPPPGGBBP5PP555Y555YYYYYYYYYYYYYJJJJJJJJJJJJJJPBGGGBBGGGPPPPPPPPPPPP5555PPGGPPPPPPPG555555555555555555555P5555PP5PP555555555555Y555YYJJ77?JJJJ????J?JJY55YYYY55JJJYYJJJYYYYYYYYYYYYYYYY    //
//    P55PPP5Y55PBGGGGGGGGGGBGGGP555555YY55YYYYYYYYYYYYYYYJJJJJJJJJJJJPBBGGGPPPPPPPPPPPPPPPPP55PPPPPPPPPPGG555555555555555555PP5P5PP5PPPPPPP5555555555555555YYJJJJJJJJJJJYYYYY5P555YY55YJYJJJJYYYYYPP5555YYYYY    //
//    GPPPPGP5PPPGBBBGGGGGPPGGBP555555555555YYYYYYYYYYYYYJJJJJJJJJJJJJJ5GGGGGGGGGGGGPPPPPPGPGGPPGGGGGPP5PGGP5555P555555P5555PGPPPPPPPPPPPPPPPPP5555PP5555555YYYYYYJJJJYY5YYY5YYPP5555555YYYYYYY5555PPP555555YY    //
//    GGP55PGGBGGPPGBBBBGGGBBBG55555555555555YYYYYYYYYYYJJJJJJJJJJJJJJJ?YGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPP55555P5PP55555555PPGBGPPPPGGGPPPPPPPPPPPPP5555555YY555YJYYYY55Y55555Y5555P555555555Y555555555555555    //
//    GGPPPPPGPGGP5GBBBBBBBBBP5555555555Y555YYYYYYYYYYYYYJJJJJJJJJJJJJJJ?YGGBBBBGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPP5PPP55555555PPPGBGPPGGGGGGGGGGGGGPPPPP55555555555JJJYYYYY55555555P5PPPP555555Y5555555PPGGPP555    //
//    PGGGP5YPPP55GBBB#BB###P55YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJJJJJJJJJJYGBGBBGGGGGGBGBGBBGGGBBGGGGGGGGGGGGGPGPPPPPP555555PPGBBGGPGGPPGGGGGGGGGGPPP5555555555555YYYYJY5555PP5555Y5P55555555Y55PPPPPGGGGPPP55    //
//    5PPGGPPPPPPG#BB#B#BBBBGGG5YYYYYYYYYYYYYYYJ??????7?????J??J?JJJ??7?GBBBBBGBBBBBBBBBBBBBBBBGGBBBBGGGGBGGP5PPPPPPPPPP55PPPPGBGGGGGGGGGGGGGGGGGGGPPPPPPPP55P5PPPP5YYY5555GP55555PPP55P5555555555P5PGGGGGPP5P    //
//    PGGGGGGPP55P##B#BBBBBBBBBPYYYYYYYYYYYYYYYJ7!!!!!!!!!!!!!!!!!!!!!!7GBBBBBBBBBBBGBBBBGBBBBBBBBBBBBBBB#GPGGPPPPPPP55PPPPPPPGGGBGGGGGGGGGGGGGGGPGGPGGPPPPPPGPPPP55Y555555PGPGGGGBBGP555555PPP55555PGGPPGPPPP    //
//    PGGGGGGPP5PG#####BBB#BBBBGYYYYYYYYYYYYYYY?7!!!!!77!!!!!!!!!!!!!!!!5#BBBBBBBBBBBBB#BGBBBBB#BBBBBBBBB#BGGPPPPPPPP5PPPPPGPPPPGBBGGGGGBGBBBBBBGPGGGGGPGGGGGPGPPP5YY5P55PPGGGGGBBBBGGPGGPP55GPPPGGGGBBBBBBBGP    //
//    PGGBBGBBGGB#######B5GGGGPPYYYYYYYYYYYYJJJ?77777!!!!!!!!!!!!!!!!!!!75PGBB##########B########B##BBBB#####BBBBBBGPGGGGBGGGGPP5GBGGBBBB#BBBBBBBBBBBBBGBBBGGGGGBBGP5555PGBBBBBGPGGGGGBGP55P5PP5PGBBGGGGG55PY5    //
//    5555PGGGP555YYYJYYYYYYY??JYJJJJJJJJJJJJJ?77777!!!!!7777777!777777777??JJYY55PPG5YJ?JY55JJ5PGBBBBBBBGGBBBBB##BP5###BPPPP555YYYYY5GGGPP5PPGGGBBBGY5555YYYYYY55555PY7J5YYYJ??77???JJJ????????J??77?????????    //
//    YYJ?JJJJJJJJJJJJJJJJJJYYYYYYJJJJJJ??JJJJJJ?7777???JJJJ??J???JJJJJJJJJJ?????????7?????????7??JYJJJJJJJJJJJJJYJ?JYYYJJJJJJJJJJ?J??????JJ???JJ????77??????????77777777777777777777777???7???7????????77????    //
//    JJJJJJJJJJJJJJYYYJJYYYYYYYYYYY?!7?JJJJJJJYJJJYYYYJYJJJJ?7JJJYJYY?7?J?J???77?J?JJJJYYYYYJJJJJJJYYYYYYYYYYY?JJJJJJJ??JJJJYYJJJJJJJJYYYYYYYJYJ?JJ?????????????????77?7777???????????????J?JJJJJJJJJYYYJYYYY    //
//    JJJJJJJ???7777?JJJYYYYYYYYYYJ?7777?JJJ??7?JJJYYYJ?77?77??JJJ??7777777777777?JJJJYYYYYYYYYYYYYYYYYJJYJYYJJJJJJJJJJ??7!7YYJ?JJJJJJYYJJJJJJJ?????JJJJJJJJJJYYYYYYYJ???JJJJJJJJJJJJJJJJJJJJYJJYYYYYYYJJJJJJJ    //
//    ??J?J???????????????????????????????????77??????77!77777??7777?777777777777777?7???????????????????????77777777777777???7777????????????????????JJJJJJJJJJ???????????????????J??????????????????????????    //
//    ??????????????7??????J???7777777777777777777777777??????7???JJJJJJJ????????????????????????JJ???????????JJJJJJJ?????J?????JJ?????JJJJJJJJ??JJJJJJJ????????J?J????JJ???JJJ?J??J?JJJJJJJJ???????JJYJJYJYYY    //
//    77????????????????????7???????????7?777?????????JJ?J????7J??YYYYYYYJJ??JJJJJJJJJJJ???JJJ????JJJJ?????JJJYYYYYJJ????JJJJJJ??????JJJJ????J????JJJJJJJJJJ?JJJJJJ?????????????J???????????J?????????JJ???JJ?    //
//    ?????J?????????7777777777???????????????J????????JJJ????J???JJJJJJJJ???????????JJ?JJJJJJJJJJJJJJJ?JJJJJJJJJJ??????????????????????????????????????????J??????????????JJJJ??JJJJ?????????7777????????????    //
//    ??????????????????????7???????????????JJJJJJJJJJJJJYYYYYYYYYJJJJJJJJYYYYYYYY5555555555555YYYYYYYYYYYYYYYJJJYY55555555YY555555555555P55555YYYYYYYYYYYY555YYJJJJ?????JJJJ????JYYYYYYYYYYYYJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJYYYYYYYYYYY55555JJJJ???JJJJJYYYYYJJJJJJ?JJJJJYYJ??!!!7!!!7??77??7?????JJJJ?J77777???7??!!!!!~~~~~!777?Y555P55PPPGGGGPPPP5YYJ7777????J?7???JJJJ???77!7???JJJYJ??JYYYYYYYJYYYJ??JJJJJY55555YYYJ    //
//    JYYY5555PPPPPPPPP5YYJJJJ??7!!!!7777777??????????J?!!!!!7777!!!!777????7!777777?7!7?J??JJYY55JJJJJJJJJYYY5555PPPGGBBBBBBGGGBBBBGPP5P55YYYY5J7???JYYYYYYY555Y555YYYYYY55PPPP555555555555YJJYYY5Y555P5YJJJ?    //
//    77?JPBBBP5YJJYYJJ7777777!!!!!7777777!!!!!7777777!!!!!!!!!!777777YPGBBBGGBGBBGBBBBB#BBBB#########BBBBBBBBBBBBBBBBGPGGGGBGGGBBGGGGBBBBB##GBBBGGGBBGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPP55555PPPPPPPPPPPPPPPPPPPP    //
//    BGGB####BGP55YY5PGGPPP55YYYYJJJJJJJJJJJJJJ?????????????????????7Y#####################BBBBGPGGPPG5555YY55YY55Y5JJ555555Y5GGP5PPPPP5PPGBGBBBBBGGGGGGGGGGGGGGGPPP5PPGGGGGGGGGGGPPPPPPPPPPPGGGGGGGGGGGGGGGG    //
//    ###########BBB###########BBBBPYYYYYYYYYYYJ??????J??????J???????7?B#################B##########################BBB####BBBBBBBBBBBBBBBBBBBBBBBBGGGGGPPPPPGPGGGPPP55PPPPPPPPPGGGGGGGGPPPPPPPGGGGGGGGGGGGGGG    //
//    #BBB####BBBBBBBBBBBBB#######BYYYYYYYYYYYYY?????????????????JJJJJ?5#########BBBBB#####BBBBBB################BB####BB#BBBBBBBBBBBBBBBBBBBBGGGGGGPPPPPPPPPPPPPPPPP55PPPPPPPPPPPPPPPGGPPPPPPPPGGGGGGGGGGGGGG    //
//    BB#####BBBBBBB##BBBBBBBBBBBBGP5PP555YYYYYYYJJJJJJYJYYYYYYYYYYYYYYP##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGBGGGGGGGGGGGGGGGPPPPPPPPPPPGGGPP555Y55555555555YY555PGGGPPPPP5PPPGGGGGGGGGGGG    //
//    BB###BBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGPPPP555555555YYYY5YYYYYYYYYYYBBBBBBBBBBBBBBBBBBBBGBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPGPPPPPPGGGGGPPPYJJ???777???J?7!77?JYJ?J????7?JJJ5YJ77??77??Y    //
//    B###BB#BBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGPP5555555555YYY5YYY5YYYYJPBBBBBBBBBBBBGGBGGGGGGGGGGGBBGGGGGGGGGGGGGGGGGGGPGGGGGGGPGPPPPPPPPPPPPPPPPPPPPPP5PPPPP5555555555555PPPPPPPPPPP5P5YYJJJ??????JY55YY555555    //
//    BBB#BBBBBBBBBBBBBBBBBBBGGBGGGGGGGGGGGGGGP555555555YYYYYYY555YYY5BGGGGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPP555PPPPPPPPPPP555555555YYYYYY5555PPPPPGGGGGGGGPGPGGPPPPPPPPGGGGGPPPPPPP    //
//    BBB#BBBBBBBBBBBBBBGBGGGGGGGGGGGGGGGGGGGGP555555555YY5YY5YYYYYY5GBGGPPPPPPGGGGGGGGPPPPPPPPPGGPPGGGGGGGGGPGGGPGPGGGGGGPPPPPPPPPGGGGP5PGPPPPPP555YYYYJJJJJJ??7?YY5555PPPPPPPPPPPPPPPPPPPGPPPPPPPPPPP555PPPP    //
//    BBBBBBBGBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGP55555555555555YYYYYYY5GGGGGPP55555PPPPPPP5555555PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555P55555555555J77777777!!!!7?JYY5555PPPPPPPPPPPPPPPPGGPPPPPGPPPPPPPPPPP    //
//    BBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGG555Y55555555555YYYYYY5PPPPP55Y55555YYY5555555555555555555PPPPPPPPPPPP555PPP5555555PPPP55555555555YYYYYJ7!!!!!!!!~~~~~~!JYJJJYYYYY555555PPPPPPPPPPPPPPGPPPPPPPPPYJ    //
//    GGGGGBGGGBGGGGPGGGPGGGGGGGGGGGGGGGGGGG5555Y5555YYYY55YY55555PPPPPP555YYYY555Y5YY555555YYYY55555PPPPP555555555YYYYYYYYY55YYYYYYYYJYJJJYJJ?77!~~~~~~~~~~~~~~~~~~!777777??JYYYJJY555555555PPP555555PPPPPP55    //
//    YYYYY555PGGGGGGGGGGGGGGGGGGGPGGGGPGPP5YYYY5YYYYYYYJYYYYPPPPPPPP555555YYJJJJJJJJJJJYYYYJJJJJJJYY5555YYYYJYJJJJJJ???JJYYYYYYYYY55YYYYJJ??77~~~~~~~~~~~~~~~~~~~~~~!!7??JJYYYYYYYYYYYYYYYYYYJJYY?????7777777    //
//    YYYJYY5PPGBGGGGGGGGGGGGGGGGGGPPPPPP5YYYJYYJ??7JYYYYY55Y55555555555Y55YJJJJJJJJJJJJJ????77777?JJYYYYYYYJJJJJJJJJ?77777??JJYYYYYYYYJJ?7~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~!!!77??????JJYJJJJ?77!!??7!!!~!!!!~~    //
//    BGBBBBBBBBBGGGGGGGGGGGGGGGGGGGP555YYJ?77777!!!7?JY555YY5555YYYYYYJYYYJ??JJJJJJJJ??7777!!~~~~!!77?JJJYYJJ???77!!~~~~~~~~!7777???777!~~~^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~!!77?????JJ?7!~~~~~~~~~~~~~~~~~~    //
//    GBBBBBGBBBBBBGGGGGGGGGPPPPGGGGPGPP555Y77!!!!!!!!77??JYYYJJJJ????7!777!!!!!!!777777!~~~~~~~~~~~~~~!!77?77!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^~~~~^~~~~~~~~~~~~~~~~~~~~~~~~!~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    55YYY5Y555PGGGGGGGGGGPPPPPGGGPPPPP5YJJ!!!!!!!!!!!!!!!7777777!!!!!~~~~~~~~~^~~~~~~~~~~^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    5YY555PPPPGGGGGGGGGGGPPPPPPGPPP555YJ7!!!~~!!!!~~~~~~~~~~!~~~~~~~~~~~~~~~~~~~~~^~~^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    GGGGBBBGGGGGPPPPPPPPPPPPPPPPP555Y?777!!!!!~~~!~~~~~~~~~!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CELL is ERC721Creator {
    constructor() ERC721Creator("Cellscapes", "CELL") {}
}