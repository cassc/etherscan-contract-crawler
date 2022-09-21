// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Winter in Massachusetts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    B######B######BBBB#B#BGBGGGGGPPGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#########    //
//    ##&##BBB#####BBBGBBBB#BGPPPPP55GGGBBBBBBBBBB&&#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##B###BBBBBBBBBBBB####    //
//    BB###&#######BGGBBBBBBGP55P55PPBBBBBBBBBBBBB&&&BBBBBGGGGGGGGGGGGGGGGBBBBBBBB##########BBBBBBBBBB####    //
//    GGBB&&#BBBB#BBBGBGGGGGGP55P55PGGGGGGGGGGGGGGBBBGGGGGGGGGGPPGPPGGGGGGGBBB################BBBBBBBBBBBB    //
//    GBB##&&#BBBB##BBBP5PPG5Y5Y5YY5PGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGBB########B##&&&&&##BBBBBBBBBBB    //
//    BB######B##BBBBBGGPPPPP555555PPPPPPP5PPPPPPPPPPPPPPPP55555555PPPPPPPGB#########B###&#&&&##BBBBBBBBBB    //
//    GB##&&##B###BBGPGBBBGPPP5JJPGPP5YJYY5PGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPB###B#############&##BBBBBBBB##    //
//    GB###&####BBBBGPGBBGP55GG5JYYJYYYYJYPGBBG#&&##########PPPPPP######BBBB#B############B#####BBBB###&&&    //
//    B##########B#BBG5GPPPGGGP5Y5P555PGPPB###GB&&#########B5GGGGPB#####GBBBBBB#B##&###############&&&&&&&    //
//    BB########BBGGGG55PPGGGGPYJY5Y5GBBPP####GB#######BB##B5GGGG5B##B##GBBBBBB###&&###########&&&&&&&&&&&    //
//    B#BB#####BBGP5P55PPP55555JJJY55PGBPP####GB####BBBBB##B5PPPP5B#BBBBGBBBB##############&&&&&&&&&&&&&&&    //
//    GGPYGBBB#BBGGPPPGPGP555YYJJYY55P5PGGGGGGPGBBGGGGGGGGGG555555GBBBBBGBBBB###########&&&&&&&&&&&&&&&&&&    //
//    BBG5PGPBGG#BBGGGGGPPP55YYYJYYY55YYYYYYYYJJJJJ???????77777777??JJJYYGBBB###########&&&&&&&&&&&&&&&&&&    //
//    &###GGPGPPGBBGGGGGP55YYJJYJJYYYY5YJJJJYYJJJ??7777!!!!~^^^:^~~!!7?JYPGBBB####&&#####&&&&&&&&&&&&&&&&&    //
//    &&&###GGBBGPP5PGGPPPYYYJJY555YJY5Y?JJYYJJ??775Y?7!~^^:.   ..:~!!7Y5GBBBB#####&#####&&&&&&&&&&&&&&&@&    //
//    &&&&&&####BGPPPGPPPP5YJJJJJJYJY5JJ?JY??7!7?77PPJ7!~^^: ..::.:~777YYPBBBB###B#&#####&&&&&&&&&&&&&&&@&    //
//    &&&&&&&#B##BBPPGGGGBGG5PPPPP5YYYY??Y5JY7!??77GGY?7!^^:.^~!~:^!?77YYPBBBB#####&&&&&&&&&&&&&&&&&&&&&@&    //
//    &&&&&&&&#BB#GPPPGGBGGG5PGGGPP5GG5YY5G5577YY7?PPY??J7!^:!???^^7?77YYPBBBB#####&&&&&&&&&&&&&&&&@&#&&&&    //
//    &&&&#&&&##BBBBBBBBBGGGP55GBBBBBBP55PPP5??YY??PPYJJ??7!:7JYJ^~J?!J55PBBB#######B###&&&&&&&&&&&@&&&&&&    //
//    &&&&&&&&&&&##PB###B###GGB#BBB###BGGGGGGPPP5J5555YYJJ?!^~!7!~!Y?!J55PBB#####GPGBBBB##&&&&&&&&&&&&&&&&    //
//    #############GB######BGBBBBBBBBBBBGGGGGPPP5YYYJYYYY5J?~~~~~~75J755PGBBB###GYY5PPGBBBB&&&##&&&&&&&#&&    //
//    BBBBBBBBBB###BGBBBBBGGPPPPPPPPPP555555YYYYJJJ??J??JJY5J?7????JJYPGGB#####B5Y555PGGGGB#&&&##########&    //
//    &###########&BG#####BBGPGGGGPPPPP5P55555Y55P5YJJJ?YJJ55JJYJYY55PPGPG###&##BPGGGGGGBB##&&&&&&&&&&&&&&    //
//    &&&&&&&######BPB##BBBBBGGBBBBGGGGGBGGGPGPGGPPPPPP5P5?777!!777?JY5PGP555PPPPGGBBBBB#####BBBBBBBB###&&    //
//    &&&&&&&##B###BPB#BBBBBBBGBGGGGBBBGBGPGGP5GGGPY5P5PPY7!!!!~~~!!!7???J?JJY5YJ???JJYY5PPPPPPPPPPPPGGGGB    //
//    #######BBBBBBBPGGGPPPPP555J??JJYYYJJ?JJJJYYYJJ?????77777!!!!!!!!77!!7?5PPPG5J7??JJY55555555PPPPPPGGG    //
//    5PP5PPP5Y5YJY5JJ??777!!!7!!!!~~!!~~~~~~!!~~~~~!!~~~~~~~!!!!!!!!!!!!!!!7????????7??JJJJJYYY555PPPPPPP    //
//    5Y5YY5YJJYYYJJJ?7!!77!!~!!~~~~!!~^^^^~~~~^^^^^^^^^^^^^^^^~~~~~~~!!!!!!!777777??????JJJJJJJJYY55PPPPP    //
//    P5PPPPP5JYJJJJJ???777!!!!~~!~~~~^^^^^^~~^^~^~~~^^^^^^~~^~^~!!!!~!!!7777777777??????YYYYYJYYY5555PPP5    //
//    BGGGBGGG55555YYJJJJJ?7?J?!~!!!!!!^~~~~!~^^~^~~!!~~~!77777?7777????77????JYJYYYYYYY5PP5PP55555555PPPP    //
//    ########BBBBBGGGGPP5YJJJ??77!!!!~~~~~~~~^~~~~~!!77?JJJYY5555PPGGGGGGGGPPGBGGGBGBBBB#BB###BBBBBBBBBBB    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WIM is ERC721Creator {
    constructor() ERC721Creator("Winter in Massachusetts", "WIM") {}
}