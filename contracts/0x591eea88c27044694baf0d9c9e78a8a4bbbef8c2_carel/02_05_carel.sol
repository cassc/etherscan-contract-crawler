// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CAREL'S ARTWORKS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    YJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ??????????????????????????????????????777777    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ??????????????????????????????????????77777777    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?JJJJ?????????????????????????????????????77777777777    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ???JYJJYJYJJ7???????????????????????????????????7777777777777    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ??JJYYYYYY??YJJ???????????????????????????????777777777777777    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?JY5YJ?????????????????????????????????777777777777777777    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?JJJYJYYY?JJ???????????????????????????7777777777777777777    //
//    JJJJJJJJJJJJJJJJJY5YYJJJJJJJJJJJJJJJJJJJ?????J5PY5Y?JJ?????????????????????????777777777777777777777    //
//    JJJJJJJJJJJJJJJJJJ55555YJJJ?JJJJJJJJJ?????JYYY5P55JJ?J??????????????????????777777777777777777777777    //
//    JJJJJJJJJJJJJJJJJJJY5PP555JJJJJ??J?????JJJJYY5PP55JY77????????????????????77777777777777777777777777    //
//    JJJJJJJJJJJJJJJJJJJJY5PPGP55Y55Y5Y5Y5GGGGPPP555Y557?????????????????????7777777777777777777777777777    //
//    JJJJJJJJJJJJJJJJJJJJJJYPGGGPPPGBBBB##&##GPPPG5555Y??JJJJ??????????????777777777777777777777777777777    //
//    JJJJJJJJJJJJJJJJJJJJJJYPGGBGGGPGBB####BGGGY5GBPJ5JJ?JJJJJ???????????77777777777777777777777777777777    //
//    JJJJJJJJJJJJJJJJJJJJJJJJ5PBBBGGBBBBBBBBBGPYPP55JYYY?JYYYJJ??77????7777777777777777777777777777777777    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJYGBBB#BBBGBGGG55GGBP5YJYYYYYYYYJJJ??77777777777777777777777777777777777777!    //
//    JJJJJJJJJJJJJJJJJJJJ??????5GGB&#GPPPG5Y5PPPP55JYYYYYJJJJJJ???7777777777777777777777777777777777777!!    //
//    JJJJJJJJJJJYYYJJJJ????????JYG#&#GPGP555PP555YYYJYYYYYJJJJJ??777!7?777777777777777777777777777777!!!!    //
//    JJJJJJJJJYY55YJJ???????????J#&&#BBPY555555YYYYJJJJJYYYYJJJJ?777!7?7777777777777777777777777777!!!!!!    //
//    JJJJJJJJY5PGPYJJ???????????Y#&BGBGPYJJJJJYJJJ?????JJYYYJJ??7!!!77??7777777777777777777777777!!!!!!!!    //
//    JJJJJJJY5PBBP5JJ???????????JG&GGGGGYJJJJJJ??7!~:^7555JJ??77!!~~!7J?777777777777777777777777!!!!!!!!!    //
//    JJJJJJY5PB#BP5JJ????????????JB####BGG5YYYPGP5YJ~:!YY5?77!!!~~^~!!??7777777777??JJ??77777777!777777!!    //
//    JJJJJJYPG##BP5YJ?????????????JBB#&&&#Y~YBGG##PJ~^^?J5?7!!!!~~^~~~7?!!7777777?JYPG5J?777777!77?JJJ?77    //
//    JJJJJY5PB##BG5YJ?????JJJJJ????5BB#&&#J^7PGGG5?~^:.!YP7777!!~~^~~~!7~!777777?JYPB#G5J?7777!!7?J5GPP5J    //
//    JJJJJYPG###BG5YJ?????JJYJJ?????5GGGGG!:~?5PY?~^::^?PY77?77!!~~~^^!7!!777777?YPB###PY?7777!77?YP##BBG    //
//    JJJJY5PB####G5YJ????JJYYYJJ????J5GBBG~:^~5PY!^:::?YP?77?7!!!~~~^^!?777777?JYPB####B5Y?77777?YPB#####    //
//    JJJY5PG#####G5YJJ??JJY5P5YYJJ?JY5GBBGY?7!7??~^:.!JPY77777!!!!!~~~7??7!???JYPB######G5J?777?YPB######    //
//    JYY5PGB#####GPYJJ??JY5PBGGPYYJJYPB#BGBP?!~~~!^.:7JG???7!!!7!77!!~?J?!!7JJYPB########GYJ??JYPB#######    //
//    5PGBBB######BP5YJJJJYPG###GP555PG##BBBBP5?!~!^::?5GYYY77777!777!!??7!777J5G#########BP5YY5G#&#######    //
//    PB###########GPYJJJYPG#####BGGGB##&#BBB#GJ!~~^^7PGBG55Y???777777!7777J?7!JG##########BBGGB#&&&&#####    //
//    B############BP5YY5PG#############&&##BBB57~!7YB#BBBBGPYJJ?7????7!77J5J?7!7P##############&&&&&&&&&#    //
//    ##############GPP5PB#&############&&&&&##BPPGB####BBB##BPYJ??7777!!7Y5YJ?!~!5&#############&&&&&&&&&    //
//    ############&##BBBB#&&############&&&&&&&######BBBBBGGGB#BGYJ??7777!77???7~~!G&############&&&&&&&&&    //
//    ###########&&&&&&&&&&#############&&&&&&&#######G5Y?!~~~~~~!!!777777777777!^^?&&#######BB###&&&&&&&&    //
//    ###########&&&&&&&&&&#######B#####&&&&&&&#####BP5YYJ7~^^:......^!777!!!777!~^!#&&######BB###&&&&&&&&    //
//    ##########&&&&&&&&&###############&&&&&&&####B55PPP5J7~^::.......~!!~^~^~~~^^~B&&&######BB###&&&&&&&    //
//    ##########&&&&&&&&&################&&&&&&&##BPPPPPPP5?~^:..   .. .~~~^^^^^^^:^#&&&&#####BB###&&&&&&&    //
//    ##########&&&&&&&&#################&&&&&&&#BPPPPPPPP5?!^:..   ....:^^^^^^^^^:^B&&&&##########&&&&&&#    //
//    #BBBBB###&&&&&&&&##################&&&&&&&BPPPPPPPPGP?!^::........:::::^^^~^:^B&&&&###########&&&&&#    //
//    #########&&&&&&&&###################&&&&&G5PPPPPPPGG5?!^:::.......:::::::~^::^P&##############&&&&&&    //
//    #########&&&&&&&####################&&&#P5PPPPPPPGGG57~^::::.....::::::^^^:::^YBBBBBBBBBBBBBBB######    //
//    ###########&&&###########BBBBBBBB#####BP5PPPPPPPGGGPJ7~^:::::::::::::.^^^^^::^?BBBBBBBBBBGGGGGGGBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBP55PPPPPPGGGGPY?!~^:::::::^^^::.:^~^^^:^~?GBBBBBBBBBBBBGGGGGGGG    //
//    GGGGGGGGGBBBGGGGGGGGGGGGGGBBBBBBBBBG555PPPPGGGGGGG5J7~^^^:::^!7!~^::::^~~^^~~!?GBBBBBBBBBBBBBBBBBBGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBGP55PPPPPPGGGGGG5J7!~^^^:^?5PY7~^::::^~~~~!!7JGBBBBBBBBBBBBBBBBBBBB    //
//    GGGGGGGGPPPPGGGGGGGGGGBBBBBBBBBBP555PPPPPPGGGGGPYJ?!~^^^:!5PGPJ7~::::::^~~!777YBBBBBBBBBBBGBBBBBBBBB    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGBG5555PPPPPPPPPPP5J?7!~~^^^?555PPJ!~^:::::~~!777JPBGGGBBBBBBBGGGBBBGGGG    //
//    GGGGGGGGGGGGGGPPPPPGGGGPPGGGGP5555PPPPPPPP5YY??7!~~^^^~Y5YJJJJ7!~^^::::~!777?5GGGGGGGGGGGGGGGGGGGGGG    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract carel is ERC721Creator {
    constructor() ERC721Creator("CAREL'S ARTWORKS", "carel") {}
}