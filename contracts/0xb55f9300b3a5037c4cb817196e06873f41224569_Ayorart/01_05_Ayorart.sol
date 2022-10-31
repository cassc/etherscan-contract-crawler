// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: transcendence
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&########&&&##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&#&&#&###################&&&&#&&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&#&&################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    ########&&&&&&##########&&&&########&&#########&&&##################################################    //
//    ########&&&&&###B########&&&&&&###&&&&&##########&##################################################    //
//    ##########&&&###########&&&&&&&&&&&&&#&#############################################################    //
//    ######P?J5B###########&&&&&&&&&&&&&&&&&#####&###BP##################################################    //
//    ######PJJJJPB########&&&&&&&&&&&&&&&&&&&#######BP5##################################################    //
//    ######GJJY5GB#######&&&&&&&&&&&&&&&&&&&&&&&&###BG5##################################################    //
//    ######PJYJJPB###&#&#&&&&&&&&&&#&###&&&&&&&&&###B55##################################################    //
//    ######P?J55PB##&&&&&&&&&&&&#BB&&B##&&&&&&&#&#BBGP5##################################################    //
//    ######BPY??J5G#&&&##&&&&&&&&##&&&#&&&&&&&&##BP5J?Y##################################################    //
//    ######BBBGJ7?J5B##&&&&&&&&&&&&&&&&&&&&&&&#BPYY?7JB##################################################    //
//    BBBBBBBGGGBY7?JY5PB##&&&&&&&&&&##&#B#BBG5YJJ?7!?GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBGGBGGY7!7777?Y5PPPB#PB&&&&&P7Y??77?7!!!YGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBGPGGGPY?777!75PGBBB#&B5B&&#&GJY7JJ?7!!!7?J5PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBB5????????777?JYPGB#####BBB#BG##BG55J!!7777?JBBBBBBBBBBBBBBBBBBBBBBB####BBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBB5??????7!!7????77?J5G###BY?P###&&#G57!!77??YBBBBBBBBB######BBBBGBB##########BBBBBBBBBBBBBBBBBB    //
//    BBBBBBPYYJ???7!777??777????JP##BJB&&#GY?77?!7????JBBBBB####B####BGGGP5BBBBBBB##&#####BBBBBBBBBBBBBBB    //
//    BBBBBBG5YY55J!77?777777?7?7?75#&B&#PJ777777!~!?5PPBBBB###B###BYYYJ?7!7J??JJYPYPB#&&####BBBBBBBBBBBBB    //
//    BBBBBBGGGP5Y?7?7?777?7?777???7?Y5Y?7777777777!!7?5BBBB##BBBG5J7?5GBBGBBBBGP5J7~JYPGB&&##BBBBBBBBBBBB    //
//    BBBBBBG5J?7!!77?7?777?7777777!7777!7!!!777?7?7!!YBB###GP5YJ~^J5#&&&&&&#####5YYP5~7JJ5PGBBBBBBBBBBBBB    //
//    GGGGGB57??7!??77?7!!7???77?77??77?7!7777!77??7?PBBBBGYYG5J!~J#&&&&&&&&&&&&#####&B575PY?YGBBBGGGGGGGG    //
//    GGGGGBY!!!77??7?7!!!!?????JYPG?7?JP77??77?!7??PBBGGY7G#P!YYB#&&&&&&BPPG#&&&#####BBPJ?GB??PBBBGGGGGGG    //
//    GGGGGBY7!!!????7!!!!7?5PGB##&P77??P7?5?7?77!~YBBBPY7Y##5!PB##&##&&#B5JP###&###BBBBB5!JBGY?GB#BGGGGGG    //
//    GGGGGG5???JGGBGJ??7?JYG#####BYJYY5BYJG#GGY???BBBBBJ7G#BJ5PG#&##&##B5PPP5G#&#BBBBBB#G~?5B57PBBBGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBGJ?5B#PG&#&&&##&&#PPBGGB####B#####G7!5BY7GBBBBGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBY?5#&##&&&&&##&&&BGGBB########&BBP7YGG7YBBB#BGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBB#G!JB#&&&&&&&##&&#&#B#&&&#BB##&&&#BBBY7JGBBB#BGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBB##BGP#&&&&&&&#&&&##&&#&&&&&#B&&@@@&#BBPPBBBBB#GGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBB###B&&&&&&&###&&&#&#&&&&&#BGPPB&@&#B#BBBBB#BGGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPGGPGGPGGGGGGGPPGGGGGGPPPPGBBBBB#B&#GB&######&##BBBB##&&&[email protected]&&#BBBBBBBGPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPGP5PGPPGGGGGGGPP5PGGGGGGGGPGBBBBB&&#GP&&#&&#&##BP5PGBBB#&#BGPG#&&&&BGBGBBGPPPPPPP    //
//    PPPPPPPPPPPPPPPPGGPPP5PPP555Y555PPGPPGGGGGGGGGPGGBG#&&#BGB##&&##PG#GPGG55GB#&&BGB#&###&GPBGGPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPGPP55JJJYYYYYY55555YY555PPPPPPPPGG#GB#BGGB#&&&&#BBBBBPPB##&&&BPPB#BB##BPPPPPPPPPPPP    //
//    PPPPPPPPPPP55PGGPGPJJJYY55PGBBBGGP5PPYJJJY555PPPPPGG57##G5PB&&&&&&&&&&&&&&&&&#BBPBB##PJBPPPPPPPPPPPP    //
//    PPPPPPPPPPP5555PP5JJYY555PB#BBGBGBB#BP55YJJY55PPPGGGG5YPBPPGB&&&&&&&&&&&&&&&&#GPP###5?5PPPPPPPPPPPPP    //
//    PPPPPPPPPP5Y5555YJYYY555PG#&&#&&&&&&BPPPG5YY5PP5PP55GGG5PGGB&&&&&&&&&&&&&&&&&##BG#GY5PPPPPPPPPPPPPPP    //
//    PPPPPPP555555Y55YYY55PPPG#&&&&&&&&&&#GPPGG55Y5PPPP55PGGGGPPGGG&&&&&&&&&&&&#BBGGPPPPPPPPPPPPPPPPPPPPP    //
//    PPPPPPGP5PP55Y5YYY55PGGBB&&##BB###&&&&BGGGP5Y5PPP55PPPPPPGP555PPGGGGGGGGPPP555PPPPPPPPPPPPPPPPPPPPPP    //
//    5555PGPPPPPPPP55Y55PPBB#&##&#######&&&&BBG55Y5PPPP55PPPP5GP5P5555555555555PPPP5555555555555555555555    //
//    5555PPPP555PPPP5Y5PPPB&&B#BB&##&#GB##&&BGP55YY555PPPPPP5PG555555555555555555555555555555555555555555    //
//    5555P55PP5555PP5Y5PGG#&###BB##&##BB##&&&G5555YY55PPPPPP5PGPP5555555555555555555555555555555555555555    //
//    555PPPPPPPP55PP555PGB#&&####&&&&###&&&&#B5555YJ5PPPPPPGGGGGG5555555555555555555555555555555555555555    //
//    555PPGP555PPPG5555PB#B#&&&&&&&&&&&&&&&BGGP5P5YJ5GPPPPGGP55PG5555555555555555555555555555555555555555    //
//    555PGGGGPPPPGPYY5PGBBBB#&&&&&&&&&&&&&#PPPPPPPP5PPP5PGGGP5PGP5555555555555555555555555555555555555555    //
//    555PGGGGGP55PYY5PGGGGB#BB#&&&&#&&&&&&GPGGGGPPPP55GPPPPPPPPPP5555555555555555555555555555555555555555    //
//    5555GGGPPPP5YY5PPPGGBGB#GB#&&&&&&&&#BGPBGGGBBGPP55P55PPPPGG55555555555555555555555555555555555555555    //
//    5555PGGPPP5YY55PPPPGBGGBBG#######BB##GGGGGPGBBGPP55PPPPPPP555555555555555555555555555555555555555555    //
//    5555YPPPP5Y555PPGGPGBGBGBB#&&&##&&&&BGGGGPGGGGGGP55GPPP555555555555555555555555555555555555555555555    //
//    YYYYY5PG5Y555PPPGPGG#GG#BBGPB#&&&&&#GPPGPPBGGBGGP55PPPPPG&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BBBB###&&&&#    //
//    YYYYYYY5P5555PPGPGGB#BGB#@&BGPPPGB##GPPBBGGGGGGP55YYPGGB&@@@@&@@@@@@@@@@@@@@@@@@@@@@&&#&&&&&&&@@@@@&    //
//    YYYYYYYY5P555PGPGGGB#BGGB&@@@&#BGPPPGPBGGBBPGPPP555YJP#&&#&&&#B&&&&&&@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@&    //
//    YYYYYYYYYYY5PGPGBGG#BBGGB##@@@@@@@&GG#BBGGBBBPPP5555G#&&&&###BB#B#&&&####&@@@@@@@@@@@@@@@@@@@@@@@@@#    //
//    YYYYYYYYYYYY5PBBGGB#GGBBPB&@@@@@@&BGB#BGBGPGBGPPPPPB###&&&&&&&&BG&&BGGB##&&##&&@@@@@@@@@@@@@@@@@@@@#    //
//    [email protected]@@@@@#B##BGGGBGGGGP5Y5PGBBB##&&&&@@&B#BBBBGPG##BBB#&&&&&@@@@@@@@@@@@@@@#    //
//    YYYYYYYYYYYYYYYYYY5PGGGBBGB&@@@@@&#BBBPPGBGGP5JJ??J5PPGB####&&@&#BGGBB55G##BBB##&&&&&&&@@@@@@@@@@@@#    //
//    YYYYYYYYYYYYYYYYYYYYYYY55PGB######BGPP5YY#&BGP5YJJ??J5PGBB#######G5GBB#BBB#BBBBB&&##&&&&&@@@@@@@@@@#    //
//    YYYYYYYYYYYYYYYYYYYYYYJJJJJJJJYYYJJJJJJJY#&#BBGGPP5J??Y5PGGB##B##B###&B5YP#BB#BB&#&&&&&&&&@@@@@@@@@#    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJYB&#BBBBBGP5Y??JY5PGBBB&&&##&#GPPG##BBBB&&&&&&&&&&&@@@@@@@@#    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJYB#BGPGBBBBGPY??JJYPBGB#BB######&&#BBBGB&&&&&&&&&&&&&@@@@@@#    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJGBBGP55GGBBBGPJ5YYPGGB##BB####&&#BBBBGG#&&&&&&&&&&&&&&@@@@#    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJGBBGGP5YY5GBBBG5J5GGGB####&&&&&BGBBBBBG#####&&&&&&&&&&&&&@#    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJPGP555PP555PGBBYYYPGBB&#B#&&&&BGGGBBBBBBGGBB#####&&&&&&&&@B    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJPP5YYJYPBBGP5PYYPPGB##&&&&@@&BGGGGGB#BB5Y5PPGBBB###&&&&&&&B    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJGBP5YYJY5PP5JY5PP5P#&&####&&#GBGGGBGGB#G5JJJYGGGBB#####&&&B    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJGBGPP5YJ?JYPPGGPPG#&###BBB##BBGGBBBP5PB#BP5YJ5GGGGGB#####&B    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJGBGP55PPYJY5PBBB#&&######BBPJJ??YPBBPPGB##GPYJYPGGGBB###&&B    //
//    ????????????????????????????????????????JGBBP55PP5JJJPB#&&########P~~7???77?PBGGGB#G55YJJY5PGGG##&&B    //
//    ????????????????????????????????????????JGBGGPPPGPYYYG#&#GG#&&#BBG?7^:^:~!7J7B#BG57:~5G5YYYYPPG###&B    //
//    ????????????????????????????????????????JGBGGPGGBBP5P&@@GPB#&#G5PBJ?!~^~!7J?7B&GY?!!JB&#GPPP5PB#&&&B    //
//    [email protected]@@&B#&#G5P#@&J7777777Y5G#G55PPPPG##BGG5PGBB##B    //
//    ?????????????????????????????????????????PPYJJY5PGGB&@@@@@@&&#&@#&&PP55YY5B#BGB#BB&#GPPGB##BPGGGBB#B    //
//    ?????????????????????????????????????????P5YJJJY55PB#&@@@@@@@@@@##BG##GBBB####GGBP5G##BGGGB&BGBBBBBG    //
//    ?????????????????????????????????????????55YJJJJYJYGBB##&&#@&&&@@@&BBB#BGB#BB&#GG5J?5#&#BGPB#BGBBBBG    //
//    ?????????????????????????????????????????5PY??JYJJJGPPPB#BG&&&&&&&&&#B#&#BBG##&BGBGGGB###BGGB&#P5PBG    //
//    ?????????????????????????????????????????5PYJ?JJYYPG55PBBPP#@@&&&&&&BB#&###########BGPPPGGBB#&&G5PBG    //
//    ?????????????????????????????????????????JJJJ????JYYJJJYYJYYP55555555YY555555555555YYYYYY555555YJYYY    //
//    7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777    //
//    7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Ayorart is ERC721Creator {
    constructor() ERC721Creator("transcendence", "Ayorart") {}
}