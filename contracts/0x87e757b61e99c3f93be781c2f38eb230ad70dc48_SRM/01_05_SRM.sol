// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: StarMan
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    @@@@@@@@@@@@@@@@@@@@@@&#BP55YJ?7!~^::::^:^^^^^^^~~!!7??JJYPGB###########BBB#&#BB#&&&&@@@@@@&&@@@@@@@    //
//    @@@@&@@@@@@@@@@@&#G5J7!~::~~~~~!!~^^:^~~~!~!7~^^^^^:::^^::^^~7J5GB##&###B#B#&#B#&&&&@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@&BP5YYY5PPPPPP55YYJ7!^::^~!!!~7?7~~^!~::^~~~^^:::.::~7J5G#######&##&&&#GG#&@@@@@&@@@@@@    //
//    @@@@@@@@@@&GPGGB#&&&&&&&&&&&&&&&&#BPYJ7!!!!~!!!~~~~^^~7Y7!~~^^::^^^::~!?5G#######&577JPG#&&&@@@@@@@@    //
//    @@@@@@@@&P5GB#####&&&#&&&&&&&&&&&&&&&&#BPY?77777777?J?7777~^~!~~~??!!~^^^^!JP#&###!7J5PPG&&&@@&@@@@@    //
//    @@@@@@@P55B&####&###&&&&&&&&&&&&&&&&&&&&&&&BP?!!7?JY5Y?77!7!~~!!!??7!~~~~^^^^!JP#&P??YPG#&&&@&&@@@@@    //
//    @@@@@@#YPG#BB#####&#&&&&&&&&&BB##&&&&&&&&&&&&&B5???777?7~75GP?!!!!!!~?7~~~^^~^^^!YBBBB#&&&&&&@@@@@@@    //
//    @@@@@@#YYBBBBBB#####&&&&&&&BJP#&&&&&&&&&&&&&&&###GY7!!?7:?PB#P!!~!!7!Y7!?Y!~^^^:::~?P#&##BBB#&&&@@@@    //
//    @@@&@@&PY5P5PGB########&&&#!J#&&&&&&&&&&&&&&&B5#&&#BY77?!!?YY7!^!777J57!77!!~^~~~~^^^7P##BGPB###@@@@    //
//    @@@&@@BYG5Y5G##BB#######&&B^?B&&&&&&&&&&&&&&&BJG#&&&&BJJY?7!!!?7!777J5?7!!~~7YYJ?7~^^^:7G##BBBB#@@@@    //
//    @@@@@@B?5GGB##BB########&&&5~7P#&&&&&&&&&&&&&&#GB#&&#&#P?7??777?!7?JJG?7!7J77J??J7!!^:::^JBBBBB&@@@@    //
//    @@@@@@B5YPGBGGBBBB#########&BYJYGB&&&&&&&&&&&&##&&&&####BJ7?7777!!77YGPY7?JJ????J?77^^^^^:!GBB#&@@@@    //
//    @@@@@&5GG5PGGPGBBGBBB#######&&&###&&&&&&&&&&&&###&&&&B#B##57??777?!?JGG5YY7!!!7!!~!7!^^^:^:^Y##&@@@@    //
//    @@@@@@5?Y55YPP5GBPGBB###B#####&&&&&&&&&&&&&&&&&##&&##&&####P7!7??7??JPGPPP577~~^^^^^^^^^:^^^:?##@@@@    //
//    @@@@@#BJJ5PYGP?PBGGGBB##BB#######&##&&&&&&&&&&&#&&&&#&#B##G#P!?YYJ?JJYG55GG55!~~~^^^^^^^^~:^^^?&@@@@    //
//    @@@@@&#5?PPPP55G#&&&BBB#BB#########B&&##&&&&#&&&&##&#B##B#GB#P?J??!?YPGY5PGPPY?!~^^~^~~7JJ~^^^^?&@@@    //
//    @@@@@@&JYGGBPGB###&&&&GBBB##B######&##########&&##&#&GB#BB&GB#Y!7!!JGGPY5PGGGP5Y!^!77!Y55J7!^^^:[email protected]@@    //
//    @@@@@@B?5GBBGB##BB&&@#5GBBBBB#BBB#####################B#BBBBGPBY7!?PGYJ5GGGGGPPPP?~~~~7JY?!~!~~^^[email protected]@    //
//    @@@@@@G?YPGPPGBGGB##&@P5GGGB#BGBBB########B#BBB##########BGBBPGP7?JPJ5PPPYY5GGGGGGY?~^~!!!~~~~~~^^[email protected]    //
//    @@@@@#PJJYPGPPPG#&###@@BYPPGBBGGBB##B##BB#GBB5P#######GB##GGBGG5J7YPP55PY!JJ5GPPGP5PY!!^~~^~~~~~^^[email protected]    //
//    @@@@@&?YYPGGBP5G#&&&&@@@555PGGBGGBBBB##GGBBBGBBB##BBG#BBB#GBBGB5P??YGP5GGYY5PGPGPYYPGJ!!!~~777~~~~~B    //
//    @@@@@@GJYPGGGGYGBB&@@@@@BYY5PPGGBGBBBBBBB###BBBBB##BG#GBBBGBBPBP5Y7JGYYGP5PPGPGPY5PGGYJ7J??7?7!~!!^J    //
//    @@@@@@@&#GBGGGYPB#&@@@@&@&##P5PPGGGBBBBBGBBGBB#BBG#GGBBGBBGBGGBG5Y75GGPGG55PBGP5PGGBPP5J5??????77!~~    //
//    @@@@@@@@@PGGP#PJP#&&&@&&&&&&&GPPPGGGGGPGGGG5PB#G#GBPP5BBB##BGGGG5?YG55BBBGGPGGP5PPGGPPBPJ77777?77!~~    //
//    @@@@@@@@@&GPBPPY5B&&&&&&&&&&&&&BBB##&&#&&#PGPGBBBPBPGGBB###BBBB5Y7JPP5GBBPGGPGGGGPPGGPBGJ?77?!!!!!!~    //
//    @@@@@@@@@G5GJ7Y5PG##B&&&&&&&#P?!!!?YG#&&&&BPPPGBGG5GBBGBB###G55GYJ5PGPGGBBGP5PPBBG55GBBGYJ7???!!!!!~    //
//    @@@@@@@&5YPY~JP5GG#&&&&&&#&#5^^!!77?YP#&&&PY5GPPPPPBGPGG##BB#5YPJYP5PPGB#BB55PGGGG55GG#P?J?77?77?!~~    //
//    @@@@@@BY5GP?!YPPGBB#&&&&&#&#?.^^^~?JY5B#&&#PPPGPGPGGGGGBBB#BGG?YYPB5PP5GBBP5PPGGGGPPG5GPYY?77??7?7!~    //
//    @@@@&YY5PGGPYYPPGB#B#&&&&&&#P~..:^77JP##&&#5PPGBBPGPGBGBGB##PY??5PPGGG5PGP5PGBGGGPGPP5PPP5YJ???77!7!    //
//    @@@@BYPPPPG#5YPPGBB##&&&&&&&#GJ!~~!JP##&&GY5PGPGGG5BGPBGBBBGB57?Y5YBBBGGPGGPPGBBPGGPPPPPYYY5YJJ?7!!!    //
//    @@@@@&##BGG#P?PGGPBG#&&&&&&##&##BBB##&&&&5Y5PGPPGBPBBPPPB##B5YY7J55GBBBBPGBGPGGBGGGGGGGPJYY555Y?7!!!    //
//    @@@@@@@@@PYP55GGPGBB#&&#&&&&&&&&&&&&&#GG55Y5PPPPGBBBBGPB##BGPYJ7?PGPGBBBGBBGGGBBPGGGPG5JJY5555Y?7?7!    //
//    @@@@@@@&577JYPGGBGBB&&&&&&&&&&&&#&&&P!!7JY?JYYY5PGBG5PGGBB#B5?7!5GGG5GGBGPGBGGBGGGGBGPPY55PPYYYJJJ7!    //
//    @@@@@@@G7!?Y5PPGGBBB#&&&#&&&&#&&##5J~7JYY7?7J5PPGP5Y5PGGGBGBG7J5P5PBJPGBBGBBGGGGGGGBGPP5YY5G5JJJJ?7J    //
//    @@@@@@@#YJJJ5GGGGBGG#&&BP#&&&#&#Y77?JYJJ??JYYYY55JYPGBGGGBPGPYY5P5GG5PBGBBBBBBGGBBBBBPPY55PPP5YJ??7G    //
//    @@@@@@@@&PPPPPGGPGGGB###GPB&&&&5!?J5P5??JYYYY5PYY5GGBGPGBB5JJY5YPPGGGGGGGBBBBBGBBGB#BGP55PPY555YJ?J&    //
//    @@@@@@@@#Y55GGGPGBBBB#B#GGP#&&B???J5[email protected]    //
//    @@@@@@@@@GYPPPPPPGGBB#BGGGGGGPYYYJYYJJY5YYJ?YYYYYYPGY?5YYPG5JY5PPPPGGGGGBGGGPGPGBGGBGPG5YY5PYJJYYY&@    //
//    @@@@@@@@@BY5P5PGPBGGBBBGBGGGGGP5YYYJJYYYYJ?JY5Y5PGPY?!?Y5PGPGGBGPPGGGBGP5PGPPPPGGPGBGGGGPGBPYYYYJ#@@    //
//    @@@@@@@@@@J?Y5PPPBBBGBBGBGGGGPPP55[email protected]@@    //
//    @@@@@&@@@@B!?Y55GGBGGGGGGPP555YY5[email protected]@@@    //
//    @@@@&##&@PY!7JYGGBBBBBPPPP55YJJ5[email protected]@@@@    //
//    @@@@BPPG#BGP5PPGBGBGGGPP5PPP55PPPPG5JJYY55Y??YG5555PPGGGP55GPPGGPPGGBBBBBBBBPPPPGPPGBGGGGYYY5#@@@@@@    //
//    @@@@#55PPPPGBBBGPGGGGGGG5YPGPGBGPPP5JJJYYJJJYY5PPPPPGGGGPPGBPPPPGGGGGBBGGGGGPGGGPYPGBGGG5YYP&@@@@@@@    //
//    @@@@&G5GGBBG5PGBGBBBGGPGPPPP[email protected]@@@@@@@@    //
//    @@@@@B5GGGBBGGGGBBBBBGGGGPPPGGP5555555YJYJJY5PPPGPPGGBBBGGGGGGGBGBBB#GGGGGBBGBBBBBBGG5Y5G&@@@@@@@@@@    //
//    @@@@@&5GPPBGGGGBB#BBBBBBBGP555YYYYJYYJJPP55PPG5JPGBBBBBGBBBBGGBBBBBBGGBBGBBBGGBBBBGGP5P#@@@@@@@@@@@@    //
//    @@@&#&BPPGBBBBGGPB###BBBGGGPGPPPPPPP5PPPGGGGGBGGBBBB#GGPBBBBBBBBBGGGGBBBGGGGBBBBBGGBB#@@@@@@@@&@@@@@    //
//    @@@@BBBPPPGBBBBBGB#B#BBBBBBGGBGGGGP5PGBGGBGGBBGGGBBBBBGBBGBBBBGGGGGGGGBGPYPBBBBBBGB#&&@@@@@@@@@@@@@@    //
//    @@@&#B#BGGGBB###BB#########BGGBBBBBBBBBBBBBBBBBBBBBBGGGBBGGBBBBBGGGGBGGGGBBBBBGBB#&&&&@@@@@&@@@@@@@@    //
//    @@@@BB##BGBBGBBBGB##B#######BBBBBBBB##BBBB###BBBBBBBBBBBGGBBBBBBGGBBBBBBBBBBBB##&&##&&@@@@@@@@@@@@@@    //
//    @@@@&B###GGBBGGBB#BBB#########BBB#BB##BB###BGPPPGBBBBBBBBGGGBBBBBB#BBBBBGGB##&#&#####&&@@@@@@@@@@@@@    //
//    @@@@@&B##BB##BBBBBBBBBBBB#######BB##B#####BBBBBBBBBB#BBBBBB###BB###BBBB###&&########&&@@@@@@@@@@@@@@    //
//    @@@@@@##&#B########BBBBBBBBBB##################BBBB############BB#####&&&#########BB#&@@@@&@@@&@@@@@    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SRM is ERC1155Creator {
    constructor() ERC1155Creator("StarMan", "SRM") {}
}