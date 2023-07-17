// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Satoshi Nakamoto withdraws money from ATM*
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////     //
//    //                                                                                                            //     //
//    //                                                                                                            //     //
//    //    &&#&&##&&B###BBBPGG55PP55P55PPPPPPPPPPPPPPPPPGGGGGGGGGGGBBBBBBB###&##BBBBBBBBBBBBBBBBB###########BBB    //     //
//    //    &&B###B#####BB##PGGY5555555555555PPP5PPPPPPPPPPPPGGGGGGGGGBBBBB###&##BBBBBBBBBBBBBBBBB#BBB##BB##BBBB    //     //
//    //    #########B#&#[email protected]&5GPY5555555555555555555PPPPPPPPPPPGGGGGGGGGGBBB###&#BBBBBBBBBBBBBBBBBB#######B###BBB    //     //
//    //    ##B#&#B&@B#@#B&&5PPJ55555Y55555555555555555PPPPPPPGGGGGGGGGGGBBBB###BBBBBBBBBBBBBBBBB###########BBBB    //     //
//    //    &&B#@#B&&B#@#B&&5P5JYYYYYYYYYYYY55555555555PPPPPP5555555YYYY55YYY5555555B#BBBBBBBBBB##############BB    //     //
//    //    #&B#@#B&&B#@#G&&YP5JYYYYYYYYYYYYYYYY5555555YYYYJJJYY55YYJY5J555JJYYY5GPPB###########################    //     //
//    //    #&B#@#B&&G#@#G&&YP5JJYYYYYYYYYYYYYYYYY55JJJJ????JJ55Y5??7??7Y5G??Y5PPGGPB######&&&&&&&&&&&&&&&######    //     //
//    //    #&B#@#B&&G#@#G&&Y55JJYYYYJYYYYYYYYYYYYYY??7?!!!!?JYYYPJ??7??YYYY5GGBBBBB#&&&&&&&&&&&&&&&&&&@&&######    //     //
//    //    #&G#@#G&&G#@#G&&YP5JJJJYJJJJJJJYYYYYYYYY??777777?Y55PPPGGGGBBB#####&&&&##&&&&@@@@@@@&&&&&&@@&&&#####    //     //
//    //    #&G#@#G&&G#&BG&&Y55?JJJJJJJJJJJJJJJJJYYYY5GB###&&&&&&#&#################B#&&&&&&&&@@@@@@@@@@&&&&####    //     //
//    //    #&G#&BG&&G#&BG&&J5Y?JJJJJJJJJJJJJJJJJJYYY5G#&&&&&&####BBBBBGGGGGGGPPBB#BB####&&&&&&&&@@@@@@@&&&&####    //     //
//    //    #&G#&BG&&G#&BP&&JYJ???????JJJJJJJJJJJJ?JY55GB&&&&##BGGGBGGGGPYYY?YJYGBBBGB######&&&&&&&@@@@&&&&&&###    //     //
//    //    #&G#&BG&&G#&BP&#JYJ7??????????JJJ5GPYJ5PGGBGB#&&&##GY5PGGPP55Y555PPPGGGGPG######&&&###&&@@@&&&&&&###    //     //
//    //    #&G#&BG&&GB&BP&#JYJ7?????????????JY5JYPGBB###B#&###BGPP55555555PPPPGGBBPPG######&&&###&&@@@&&&&&&###    //     //
//    //    #&G##&BG&&PB&BP&#?YJ77???777??7?JY5P55YYPGBB##B#&&#BBGGGGBBBBBB#######PP#########&&&&&@@@&&&&&&###      //    //
//    //    #&G#&BG&&PB&BP&#?JJ7???7777!!7JYYY55PGBBGGB#####&&@&&&&&&&#########BBBG55P#####&&&&&&&&&@@@&&&&&&###    //     //
//    //    #&G#&BG&&PB&BP&#?JJ777777!~~!!!77??JY5PBGPGBB&&&#&&&&&##BBGBGGGP555YYYP55P######&&&&&&&&@@&&&&&&&###    //     //
//    //    #&G#&BP&&PB&BP&#?JJ77777~~!?77JJY5PGGPPGBGPPB####&&@&##BBGGGPPPJ!YJJPBBP5P######&&&&&&&&@@@&&&&&&&##    //     //
//    //    #&G#&BP&&PB&BP&#?JJ7777~!7J??JY5PB##BBGGB5J5B##B#&&&&#BBBGGGGGP!JB5P5GBGPP######&&&&&&&&@@@&&&&&&&##    //     //
//    //    #&G#&BP&&PB&BP&#?YJ777!!?JJJJY5GB##BBBGGBBJ5BBBB##&&&&&@@@@@&&P7PBPGGGBG5P######&&&&&&&&@@&&&&&&&&##    //     //
//    //    #&G#&BP&&PB&GP&#JYJ7777?JJJY55PB###BGPGGB#Y5BBBBB#&&#B#&&##BGG??GBPPPPBG5P###&#&&&&&&&&&@@&&&&&&&&##    //     //
//    //    #&G#&BP&&PB&GP&#JYY777?JYJY55PGB###BBBB##&P5GBBBB#&#BG##GPPP557YBBPPPP#GPG#######&&&&&&&@@&&&&&&&&##    //     //
//    //    #&GB&BP&&PB&BP&#JYY77?JJYY55PGBB##&####&###5GBBB##&BPGBB55YY5J75BBGGGG#GPP#########&&&&&@@&&&&&&&###    //     //
//    //    #&GB&BP&&PB&BP&#JYY77JJY55PPGGB###&&&&&&&&#PGBBB###G5GB555J?J??PBBBGPGBGPP#########&&&&&@@&&&&&&&###    //     //
//    //    #&G#&BP&&PB&GP#BJYY77JY55PPGBB####&&&&&&&&&PGBB###B5PBPY5YYY555GB#BGGGBBPP#########&&&&&@@&&&&&&&###    //     //
//    //    B#PGBGPGGPPPPPPPJYY7?Y5PPGGGBB###&&&@&&&&&&GGBPPPPP5PP5YYY55555GB#BBBBBBPP##########&&&&@@&&&&&&&###    //     //
//    //    BBGBGGGGGGPPPPP5JYY7J5PGGGBBB#####&&&&&&&@#PBBPGGGGGBBGBBB###B##B#BGBBBGPP##########&&&&@@&&&&&&####    //     //
//    //    BBGGGGPPPPPPPPPPJYY?5GGGGBBB#######&&&&&#PYPBBGG########&&&&&&&&##GGBBBGPP#########&&&&&@@&&&&&&####    //     //
//    //    #BGBGGPPPPPP5555J5YJPBBBBBBB########&&&&G?JPBBPPPGGGGBBBBBBBBBBBBBGGGGGPPG#########&&&&&@@&&&&&&####    //     //
//    //    BBGGGPPPPPPPPPPPJ5YJB#################&&5JJPBBGGPPPPGGPPPP55555555GGGPGPPP#########&&&&&@@&&&&&&####    //     //
//    //    #BGPP55555555555J5Y?5PPG&&@&&&&&&&&&&&&&5JYPBBGPY5YYY5Y5PY???JJJJJ5PPPGPPP#########&&&&&@@&&&&&&####    //     //
//    //    BGGPPPPPPPPPPPP5JYY?77?7G&&&&&&&&&&&@GY5YJY5GBGP55YJJYY5PY??????J?5555GPPP#########&&&&&@@&&&&&&####    //     //
//    //    #BGPPPP555555555JYY????75&&&&&&&&&&&&BJJJYY5BBGP55PPPPPGP5J?????J?5PP5GGPG########&&&&&&@@&&&&&&&###    //     //
//    //    #GPP555555555555JYY?7??7J#&&&&&&&&&&&#YJJYYPBBPP55Y5555555555555555PPPBGPG########&&&&&&@@&&&&&&&###    //     //
//    //    BGPP5PPP55555555JYY??????B&&&&&&&###&#YYYYYPBBGGPPPPPPPPPPGGGGGGGGGGGBBGPG########&&&&&&@@&&&&&&&###    //     //
//    //    BGPPP555P5555555JYY??J???G&&&&####&&&BYYYY5PBBGPPPP555PPPPPPPPPPPPPPPPGPPG#######&&&&&&&@@&&&&&&&&##    //     //
//    //    #GPPPP55P5555YYJ?JJYJJJ?5##&&&####&&&BY5555PBBGGPPPPPPPPPPPPPPPPPPPPPGGGPG#######&&&&&&&@@&&&&&&&&##    //     //
//    //    #BGPPPPPPP5J77JYY5PPG5YGB#&&&&BB#&&&&B5555PG#&#BGGGGGGGGGGGGGGGGGGGGGGBGGB&&&&&&&&&&&&&@@@&&&&&&&&##    //     //
//    //    #BGGGGGGP5??Y5PGBBBBBGPPPG##&&###&&&B55555G#&@&###########B#####&########&@@@@@@@@@@@@@@@@@&&&&&&&&#    //     //
//    //    PPPPP5555JPGGBBB##BGGPPPPG#&&&####&&#PPPPPG#&&&#B########################&@@@@@@@@@@@@@@@@@&&&&&&&&&    //     //
//    //    GGGGGPPPPG#&BBBGGPGPYY55P#&&&&###&&&&GGGGGB#&@&###################&&&####&@@@@@@@@@@@@@@@@@&&&&&&&&&    //     //
//    //    PPPPPP555G#B#GPB55GP5PPPPB&&@@&&&&&&&#BGGGBB#&############BPG###B5GBBG###&@@@@@@@@@@@@@@@@@@@&&&&&&&    //     //
//    //    YYYYYYYYYYPPGP5GJJGYYYYYY5B#&&&###BB##BBBBGPPGPPPGGGBBBBBB55PGGGPPPGGBB###&&&&&##&#&&&&&&&&&&&&&&&&&    //     //
//    //    55555555555GPG5G55GP55555PPPPGGGPPPGGGPPGGGGPPPPPPPPPPPPPPPPGGGPPGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBB    //     //
//    //    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //     //
//    //    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //     //
//    //    BBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBGGGGGGBBBBBBGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //     //
//    //                                                                                                            //     //
//    //                                                                                                            //     //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////     //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SNWMFA is ERC721Creator {
    constructor() ERC721Creator("Satoshi Nakamoto withdraws money from ATM*", "SNWMFA") {}
}