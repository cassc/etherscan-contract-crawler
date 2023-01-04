// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@&&&&@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@&&&@@@@&&&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGP5YYJG#&&&&&&&&####&&&&&#&&##&&&&&&&&&&&&&&#    //
//    &&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@&@@@@@&&###BP5YJJJJJJYYJPPB#&&&&&&&&&&&&&#YJPPYPB&&&&&&&&&&&&&#    //
//    &&@@&&@@@@@@&&&&&&&&&&&&&@&&&&&&&&&&&&&&#PJJPGP55J777???JJYYJ555PB&&#BBBBBGP5J~7?Y5YPB&&@&&&&&&&&&&#    //
//    &&&&&@&&@&&&&&&&&&&@&&&&&&&&&&&&&&&&&&P7~~^!?5PGP?~!7777!7777??J???7!!!!7777?JYPGG#&&@@@@@&&&&&&&&##    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&G!!~^^!!~~~!~!7?7!~~~~~~~~!77?J??JY5PG##&&&@@@@@@@@&&&&&&&&&&&#    //
//    #&&&&&&&&&&&&&&&&&&&&&&&&&&&#########BJ7~::^^~!!!!?J7??7!!!7?JJJYJYYYYGBB###&&&&&&&&&&&&&&&&&&&&&&&#    //
//    ##&&&&&&&&#######&&&&###&&#########BJ~^:::::^~!!!~!P777777777JJJJ??JJJP#&&#&&&&&&&&&&&&&&&&&&&&&####    //
//    ##&&&&&&&&&###################BB#BP!::::^:::^~!!77JG557!77777JJJ?????7P&&&&&&&&&&&&&&&&&&&&&&&&#####    //
//    #######################BBBB##BBGJ!^^^:::^:::^~~~JYYJPBPJ77777JJ?????77P&&&&&&&&#BGP5YJJB&&&&&#######    //
//    ########B####BB##B####BBB#B5J7G!^^~!::~~~^:^~^^~~~7YBGPP5J77!J???777775#BGP5YJ?77!!!!!75G#&#########    //
//    B##############BYJJYPPGPY?~JJJG?!?YP!~!^^^^~~~^^~7?B#GP5555J?J?7777!!!!7!!!!!!!!!77??7?P5P#&########    //
//    ##############BJ77?~^^^^^^^755PGB&@@P~~^^!^~~~^^^!?##GP55555JP?!!!!!~!!!!!!!!!77???J???P555B#&######    //
//    #########BB#B#BGPYJJY5PPPPGPGB###&&&@?^:^!^~~~^^^~?##BPP5555?PJ!!!!!!777???????777!!!!755555P######B    //
//    B#########BBBBBBBBBBBBBBBBBPPGGB###&@5:^^^^~~~~^^~~P#BGP5555?PJ7??????????77!!~~~!~~~~!5555YY5######    //
//    B########BBBBBBBBBBBBBBBBBBP5PPGGB##@J^^^~~!~~~~^!!~G#GP5555JGY7777!!!!!!!!~~~~~~~~~~~!55YYYY5#####B    //
//    BBBBBB######BBBBBBBBBBGGGP5PBB###&&&@?^^^^~~^^^^~!7~!BGP555P?GJ!!!!!!!!!~~~~~~~~~~~~~~!5YYYYYY######    //
//    BB#############BGPP555YYJJJG####&&&@&!^^^^~~~^^^!!!7~YBPP5557PJ!!!!!!~~~~~~~~~~~~~^~^^~YYYYYYY#####B    //
//    BB#############PYYYYYYJJJJJPBBBB#&&@P^^~~~!7!~:~J!~G?7GGP55P?PJ!!!!!~~~~~~~~~^~~^^^^^^~YYYYYYY######    //
//    ###############GYYYYYJJJJ??PBGBBB##&P:^~!~~7?~.^JY5GJ7PGP55PJPJ~!~~~~~~~~~~^^^^^^^^^^^~YYYYJJY######    //
//    B##############GYYYY5YYJJJJ?7~?PGGGBP:^^~!77?7:^!?77?YGP5555JPY~!~~~~~~~~~~^^^^^^^~~~~!YYYJJJJ######    //
//    B##############GJYY55555Y55?7?YPBBB#G::^~^^~7!:^~~!!?JBGPP5PJP5!~~~~~~~~~~!!77??JYYY5555YJJJJJB#####    //
//    ###############PJJJ?J????????JYPBBB&B::^~~^~!J^~!~!7JJGGGPP5JP5?77???JJYYY555555555555555YYJJJB#####    //
//    B##############PJJ????77777!!!!7?YP#&!:^~!~~7Y~!7!!?YY5P55555PPPP55YYYYYYYYYYYYYYYYY5555555YJ?B#####    //
//    GBB############PJJ???777777!!!!!!!!7YY^~!!!!?5?~???J5YBBBBBGPBGPPP5YYJJJYYJJYYYYYYYYYY5Y555555######    //
//    GBB###B########P??77777!!!!!!7777????Y7~!!77?PG!7?JJY5BBBBGPPBBGGGPPP5YJJYYYYYY555PPGGGBB###########    //
//    GBBBB###BBBB###P?777?????????JJJJJYYYYY?^~77JPB?^JJ?JPBBGGGPPBBGBBBGPPPP5PPGGGBB#&&&&&&&&&##########    //
//    GBBB###BBB##B##BGP5YJJJJ?JJJJJJJYYYY55J5~^?YY5B?:?J??PBGGGPPPBBGGBBBBGB&BP55PPGGB&&&&&&&&&&###&&####    //
//    GGBBBBBBBBBBBBBB####BGPYYJJJJYYYYY5555?Y?!?Y55GP~7???YGGGPPPPBBGGBGGGPB&##BGP5PPB&&&&&&&&&&&#&######    //
//    GGBBBBBBBBBBBBBBBB######BBGP555PPPGGBBYJY!?JJ5BBY!!7!7YPPPPPPBBBGGGGGGB###B#BGPPB&&&&&&&&&&&&&&##&##    //
//    GGBBBB######BBBBBBBB#BB#######&&&&&&&&5?J^7?YJGGG7~~~!?PPPPPPBBBBGGGGPGBBBGBBBBB#&&&&&&&&&&&&&&&####    //
//    GBBB#################BBBBB###&#&&&&&&&PJ?:!?J?YGG?^^~!?5PPP55B#BBGGGGPG&&&&&&&&&&&&&&&&&&&&&##&&####    //
//    BBB#################BBBBBBB###########P?J^~!??JGG5~^~!7PPP555BBBGGGGGPB&&&##&&&&&&&&&&&&&&#######BBB    //
//    GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB###P?J7~~??5GPP!^~!?PPP555GGGGGPPPPG&&&&###&&&&&&&&&&##########BB    //
//    GBB##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##P?JY!~775GGG?^~~JGPPPPPGGPPGPPPPB&&&&&&#&&&&&&&&&#############    //
//    BB#####BBGGGGGGGGGGBBBBBBBBBB#####BBB#GYYPY~~!JGGG7^[email protected]&&&&&&&&&&&&&&&&&&&&&&&&&#&#    //
//    B######BBGGGGGGGGGGGGGGGGBBB######BBBBGJJY5!^^J7??~^~!YYYJJ??JJJY5PPPPB&&&&&&&&&&&&&&&&&&&&&&&&&&&##    //
//    BBB########BBBBBGGGGGGGGGGGBBB########P??JYJ:^7?77:^~!YYYJJJ?YYJJJJYY5B&&&&&&&&&&&&&&&&&&&&#######BB    //
//    BBBBBBBBBBBGGGGGGGGGGGGGGGGGGBBBBB####PJJJYY^:~J?::^[email protected]&&&&&&&&&&&&&&&&&&&&&#######    //
//    BB####BBBBBGGGGGGGGGGPPGGGGGGGBBB#####PJJJY57:^7?:^^[email protected]&&&&&&&&&&&&&&&&&&&&&&&&&#&#    //
//    B#######BPGBBBGGGGGGGGGGGGGGGBBB######PJJJJ5?::^!^^^[email protected]&&&&@&&&&&&&&&&&&&&&&&####&#    //
//    B#######57PY5GGBBBBGGGGGGGGGGBBBBBB###PJJJJY?::^!7^[email protected]@@&@@&&&&&&&&&&&&&&&&&&&&###    //
//    GBB###GY?JGG7?PBBBBBBGGGGGGGGGGGBBBB##[email protected]&@&&@&&&&&&&&&&&&&&&&&&##&##    //
//    GBBBBBYJYPB#55BBBBBBBBBBBBGGGGBBBB##&&[email protected]&@&&@&&&&&&&&&&&&&&&&&&&&###    //
//    BBBB#BYJ5GB5YYPGGGGBBBBBB#BBBB######&&[email protected]@&&@@@@@@@@&&&&&&&&&&&&&&&&&    //
//    BB#B#BY75Y7!~!JJ7Y?JP#############&&&&[email protected]@@@@@@@@&&&@&&@&&&&&&#&&&&##    //
//    ####B#7.~!~7???!!#GYJBBBBBBBBBB####&&@B55YYYYYYYYYYYYYYY5555PPPPP5PP55G&&@@@@@@@&&&&&&&&&&&&&&&&&&##    //
//    ####&B^~!J5P777JY##GB#GGBBBBBBBB##&&&&&&&&&&###BBBGGBBBBBBBB###########&&&&&&&&&&&&&&&&&&&&&&&&&#&##    //
//    ####&5:?Y5P?!??JB&##&&GBBBBBBB##########&&&&&&&&&&&&&&&@&&&&&&&&#########&&&&&&&&&&&&&&&&&&&&&&&####    //
//    ###B&?:[email protected]&&&G?YBBBB################&&&&&&&####&&&&#&############&&&&&&#&&&&&&#&&&&&&&##&&##    //
//    B###&!^:^7?!:YPPB&##55Y5PGGGGGGBBBBBBBBBBBBBB#B#B####BB##################&&&&&############&&&&&#&###    //
//    B##&B~~^^~~^:Y#BGBPJJY?5PPPPPPPGGGGGGBBBBBBBGBBBBB###############&#####&&&&&##&&&&&&&&&###&&##&#####    //
//    B###G~!~~~~^^YB555YJ!77J5PPPPGGBBB################################################################BB    //
//    ###&Y~!~!~^^^JP?JY?7JJJ?YPP5PPPGGGBBBBBBBB######B#BBBBBBB#####BBBBBB#BBBBBBBBBBBBBBB#B###B#BBBBBBGGG    //
//    ##&&?!7!!~~^~Y5!??!7Y?77YPGPPPPPGGGGPGGGGGGBBBBGGGGPGGGGPGPPGGGGGGGPPPPGGGGGGGGGGGPGGGGGGBBBBBGGGGGG    //
//    &&&#77!!!~~~!JJ~Y!^J?7~!5BBGGGBBBBBBGGGP55JY55PPPPP555555555PPGGPPPPPPPGPPPPGGPGGGGGGGGGGGBBGBGBBBBG    //
//    ###G!!~!~^~~!?^!G~~P777?Y##PGGGGBBBBBGBGGG5PGGGGGBBGGGBGBGGGGBBBBGGGGGGBGGGGBBGBBBBBBBBGGB#B###BBBBB    //
//    GGB5~!~!^^^~~!75B~!B77??YBBY5P5PPPPPPGGPPPGPPPPGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBB##B#B#B#B    //
//    PGGJ~!~!^^^^^~JG#!!#?!?YYP#GPP5555PPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGPPPGGGGGGGGGGGGGGGGGGBBBBG    //
//    BGG7~!~!^^^~^~5BG~7BJ!?Y5GB#G5555PPPPPPPPPPPPPPPPPPPPPPPGGGPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    BBB!~~~!~^^~^!5GJ^?BY!YJPGBGPYPPPPPPGGGGGGPGGGPPGGGGGGGGGGPPPGGGGPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGP    //
//    GBG!!!!!~~^^^?5J~~Y#Y~YJPB#?YPP5555555PPGGGBBBGGPPPPPP555555PPGGGGGGGGGGGGPGPPPGGGGGBBBBBBBGBGGBGGGG    //
//    55P!~~~~7~~^^!!~~~P#Y~7J5GG7!5PPP55YYYJJJJJY5PPGGBBGPP55YYYY55YYYYJJY55PGGGGPPPPPP55555P555YY5PPPPPP    //
//    PPGJ^^~!?~^~~^~~^7BBY!7?YGP77?GBGGP55YJJ????????????JJYY5PGGGGPYYJ???77777?777??JJY5GB#BGP5YYYJJJJJJ    //
//    GGY!~~~7!~~~^^~~~P5?!7Y5YP577YBBBBBBBBBBGGGGGGPPPPPPGGGGGBBBBBBBBBBBBBBGGGP5YJ?7!7?JJYY555PPPPPP5PPP    //
//    J?~~!!!7!~~~!?7???7?^75?7J?JYYJYYYY5PGBBBBB#######BBBBBBBB#######BBBBBBBBBBGP55YYYJJ???????J??77??JJ    //
//    ~~!!~~~7?!^~!7??!7J???Y?7??J?JYJJJJYYYYY5BBB############BGP5YJ???JJY55PPPPGGGGGBBBBBBBBBBBGPY?777777    //
//    ?77777JYJ5Y55YYYYJYYYYJ??JJ?JY55JY55YYYG#P?JJYY5PGGBBG5YJ?7!!!!~~~~~~~~!!!!!!!777???JYPPP5YJ??7777?7    //
//    YYYYJYYYJJJJJJJJJJ??JJJY?JJ55PPP55YJYG#&#P?JYY5PPGGGBBBGGGGPPP55YYYJJJ??777!!!!777JYPGBBB####BGGP55P    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EJAED is ERC1155Creator {
    constructor() ERC1155Creator("Editions.", "EJAED") {}
}