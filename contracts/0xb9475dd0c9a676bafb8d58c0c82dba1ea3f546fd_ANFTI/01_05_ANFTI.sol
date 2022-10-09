// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: anftimatter
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    GGGGGGGGGGGGPPPPPPPGPGGGGPGP555555555PPP555PPPPPPPPP5PPYPPPP55P555PPPGPGGGGPPGGPPPPPPPPPPPGPGGGGGBBB    //
//    GGPPPGGGP5PP5555555555P5555555YY55555555YY55555555PP555YYYYYYYY5Y5555P55PPGPPPPPGPPGGGPPGGGPPGGGGGGB    //
//    PPPPPPPPP55555P55Y55YY55YYYY5YYY555YYYYYYYYYYYYYYYY5555YYJJJJJJJJYJYYYYYY5555PPPPPPPPPPPPGGGGGGGGPGG    //
//    PPGPPPPP55YY55555Y555Y555Y555YYYYYYY55YY5Y5YJYYY5PGB#BGGPPPPPPGGGGGG5YYYYY5555PPPPPPPPPPPPPPPGGGGGGG    //
//    GPGGPPPP55YYYYYYYYY555Y5555555YYYY5GB55B###GGGBB#&&@@@@&&@@@&&&@@@@@&##BB#BG55P5PPPPP5PPPP55PPPPGGGG    //
//    PPGGGGGPP5YYYYYYYYYY5Y555YYYJJYYY5PGG#&@&#&&&&&&&&@@&&&&&&&&&&#&&&@&&&&&&&&&#BBGGPP5P5555PPPPPPGGGGG    //
//    GPPGGGGGGPJJYYYYYYYYYJJJJ?77?JYG####@@@&&&&@&&&&&##&&#&&@@&&&&&&&@&&&&&&&&&&&@@&#BGPPPP55555PP5PPPPP    //
//    GPPPGGGGG5YYYYYYY55YJJ??JJYYG#&@&##&@&@&&&&@&&&###&&&&@@@@@@@@@&&@@@&@&&&&&&@@@@&&BGPPPP55555555PPPG    //
//    PPPPPPGP55YJJYYYYYYJJYPG#&&&@@@@@@@@@@@@&&&&&&&&&@@@&&&&BBB#BP5YYPGP555PBBBB#&&@@@&##BBG555555PPPPPG    //
//    5PPPPPPP555YJYYYYYYPB#&&@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&GYJJJ?7!!~~!~~!!!!!^^^!Y#@@@@@&&&BP555PPPGGGP    //
//    5P55PPP5555YYY5YYP#&&&&&@@@@@@@@@&&@&&&&&&&&&#BGBBB#&&B5?7!!!~~~~~~^^~^^^^^::::7B&&&&&&&&B5Y55PPPGGG    //
//    5P55555555555Y5G#@@&&#&&@@@@@@&&&&&&&&&&&##BG5YYJJJJYJ?7!!!!~~^~~^^::^:::::::.::J##&&&&&&&#BGPPPPPGG    //
//    PP55555Y5555YYB&@&&&&@@@@@@&&&&&#&&&&&&&&&&&BYJJ???7!!7?77?!!!~~~^^^^^:::^^^::.:7B&&&##&&@@@&BGGPGGB    //
//    PPP55555555Y5G&@@@@@@@@@@@&&@&######&&&&&&##B5JJYYJ7!!77777!!!!!~~^^^::^^^^^^^:.!#&&&&&&#&&###PPB#BB    //
//    PPP55555555PB#&&&&&&&@@@@&&&&&&##&&&&&&&&###GPYJYYYJ?!!!!!!~~~^~~!~^^^^^^^^^^^:.^G&#[email protected]#&&&&&#P5PPPP    //
//    PP55555555P#&&&&&#&&&@@&&&&&&&&&&&&&@&###BGGP5YJY555YJ7!!77!!~^^^~!~^^^^:::::::.:5GPP#@&&&&&&B5555PP    //
//    P555555YYP&@&&@@@&@@@@&&&&&&@@@@&&&&&B##BGGGGGP5PPP55PGP5Y5PY?7!~~~~~~^^::.::.:^^?PPB&@&&&&@&#PYYY55    //
//    555YYYYYG&@&&&@&&&&&&&@@@@@@@@@@@&&&#BBBPPBBBB#BBGP5Y5555Y5PGGP5J7~!!!~^:^?YJJ?7!7#&#&@@&#&&&GJ?JY55    //
//    [email protected]@&&&&&&&&&&@@@@@@@@@@@@@@&&#BBGP5PGBBGPPPYYYPGBBBBGPPPPGPY!~~!!7JPPB##BPPB#&&@&&&#G5????JYY    //
//    [email protected]@@&&&&&&&@&&&&@@@@@&@@@&@@@&#GP5YJ?JYPGGGBPG#&&&YY#@&#P55PG5!~~55YPGB###B##&&#&&&B5J??7???JY    //
//    [email protected]@&&&&&@@&&&&#&&&@@&&&&&&@@&#BP5YJJ?!77JYPGB&##&&#B###PY5PPYP?~?J5&&P?5&@@&@&&&&&&#GJ?????JJY    //
//    [email protected]@@&&&&&&&&&&&&&&@&&&&#G#@@&BP555YYJ77!!!?JJYPGB#@@&#B7!?5PG5!~~?#@BBPG#[email protected]@&&&@&GY?77????JJ    //
//    [email protected]@@&&&&@@&@@&&&&@@&@&#B&&&#BPPPP55Y?7!!~~~!!!?YY5GPJ~~~!5GB5~^^^J##BBBGGYB&&&#BGPJ?777?????J    //
//    5YYYJJJJY#@@@@&@@@@&&&&&&@&&&&@@&#BGGP5PPP5YYJ?7!~~~!~~~~!!??YPGGP5J!~^~~~^^^:^?GGYY????777!!!!!7?7?    //
//    5YYYYYYYYP&@@@@@@&&##&&&&##&&@@###GGP5PGGP5Y5Y?77!!~~~~~~~~~~?PGBGPJ!!~~!~~~~^!JBB5?7777777!!!!7777?    //
//    555YY555PB&@@@@@@&#&&####B#&&@&###BGPPGGGP5YYYYJ?7!!~~~~~!~~~!?PGBBGJ?J7~!~~~~7GBGG5?7!!77!77777??7?    //
//    PPP5G#&#&&&&@@@@@@&&&&&####&&##BGGGPPGPGP5YJJ?J??7!!!!!~~!!~~~~!?Y5YY7!~~~~~~~?JJ77?77!!!7!7???7??7?    //
//    5P5PB&&&BBB&@&&&&&&&&@@@@&&&&&&#GPPP55YYYYJJ??????!!!!!!~!!!!?YGB##PPPJ!~~~~~~777!7777!!!!!!77?????J    //
//    5555PB#BB####&&#B#&&&&@@@&&&&&&&#BBP5P555YYY?77???7!!!!!!!7JP#GJJJJJG5GP?~~!!!!77777777!!!!!???????J    //
//    55YYYY55PGGGGB##&#&&&&&@@@&&@&&#BBBGB#[email protected]&####GP#&##&#J~!!!!777777!!!!!!7????7??J    //
//    YYYYYYYYYYYYY5B&&&&&@&&##&&&@@#GGGGGPPYJ???7!!!~~~~~~~7!!!?PGBGPY?7?JY5P57~!!777?77?77!!!77???J???JJ    //
//    5555YYYYYYYYYYYPB#&@@#B##&@&&#PPGGBGY?77???!!!~~~~~~~~!!!!!!!777!!~~~~7!!!!!77?777!7??777?????????J?    //
//    P55555Y55YYYYYJJJJY5P#&&@&&&#GPP55GG5J?????7!!~!!!!~!~~~~!!!!!!!~~!!!!~!7!!~!7777!!77?77????????????    //
//    P55Y55YY55YYYJJJ?77?7JGB###BP555YY5P5YJJ????7!!!~~~~~^^^^^~!~~~~~~!7J??77??7!!77777?7??7?7??7777???J    //
//    P55YYYYYYYYYYJJ?777?JYPGP5JY???JJ77?JJ????J??????????7!^^~^^^^^^~!7?JJYJJJ??????????7?7777?7777??JJJ    //
//    555555555555YYJYY5PG####G5Y7!!~~~!~!!777777??7!~!7JY555J!~~^:^^~!Y#&&BPPYJ?7??????????7777??7????JJJ    //
//    PPPPPPPPPP55PPPG##&&@@@&@@&[email protected]@@@@&#P5YYYYJJJ??????????J??JJJJ    //
//    GPPPPPPPGBB##&&&&&&&@&&#&&&&&GPBBGGBGGBBB&BGY?7!~~^^^7?77!~~^^:^~J#@&&@&&&&&&&#B5J??????????JJJ?JJJJ    //
//    GGGPPGB###&&&&&&&&&&&&##&&&@&&BPPB#&@@@@@@@@&&####BGGBBGGPY?!!!?G&&&&&&&####&@@@&#G5YJ??JJJJJJJJJJJY    //
//    GGGGG#&&&&&&@@@&@&&&##&&&@@@@&&B55B#&@@@@@&&@@@##&&&@@@@&&&####&&&&@&&#&&B#&&@&&&&@&&#B5YJJJJYJJJJYY    //
//    GG##&@@@@@@@@@@@@@@@&&&@@@@@@@&&#P5#@&&&@@&&&&@@&&&&&&@@@@@&&&&&&&#########&@@@&&&&&&@@@&BGP555YYYYY    //
//    GB#&&&&&@@@@@@@@@&&&@&&&@@@@@&&@&&GP#&&##&@@&&&&&&&##&&@@@@@@@@@@&&BB##BGGB#&@@&&&&&&@@@@@@&BP555555    //
//    GGB&&&&#&&&&@&@@@&&&@@&&&@@@&&&&&&&BGB&&&&#&@@&&&&&&&&@@@@@@@@@@@@@@&&&&#G5GB#&&&&&@@@@@@@@&&##GP55P    //
//    GG#&@@&&&&&&&&&&@&&&&@@&&&@@&&&&&&&&G5B&@@&&&&&&&#&&@@@@@@@@@@@@@@@@@@@@@&##BB#&&#&@@@@@@@&&@@@&&#PP    //
//    BB&&@@&&&&&&&&&@@@@@&@@&#&@@&&&&&&&&&BPG&@@@@&&&@&&&&&@@@@@@@@@@@@@&@@@@&&&&##&@&&&&&@@@@&@@@@&@@@&#    //
//    B##&@@&&&&&&@@&&&@@@&&@&B&@&&&&&&@@@@&BPB#&@&&&@@@@@&&@@@@@@@@@@@@@@@@@@@@&&##&@@@&&&@@@@@@@@&##&&@@    //
//    B#&&@@&@&&&&@@&&&@@@&&&#B&&&&&&&&@@@@@&&#B&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###&@@@@&&@@@@@@@&###&&@@    //
//    ##&&@@@@@&&&&@&&&@@@@&@&##&&&&&&&&&@@@@@&B&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##&@@@@@&@@&@@@@&&&##&&@@    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ANFTI is ERC721Creator {
    constructor() ERC721Creator("anftimatter", "ANFTI") {}
}