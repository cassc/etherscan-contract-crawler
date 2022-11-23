// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pich Please
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ####################################################################################################    //
//    ##########################################################BB########################################    //
//    ##################################################BBGGPPPGB#########################################    //
//    ################################BB###########BP5YJY55PPPPPB########################B###BBBBB########    //
//    #############################B5PBBBB#######P?!!!!!7YY?7^::~P#####################BB##GPGB###########    //
//    #############################?5##########B7^~^::^^::::::^^:^~~7YG#####B####BB###GG#G5G##############    //
//    #############################7J#########G~^!:.:^^:^:::::::::::::^!?JYPB####GP##GG#PY################    //
//    ###########################B#G~Y#####G55!^?^:.^^:^::^:::::.:::::::^?YPB###B?B#PP#P7#################    //
//    ###########################B5#B??PBBG7!?:?7^::~::::^::::::^::^^^^^^J##BGGJ!P#BY#B~P#################    //
//    ############################PJGB5JJY5!JP:Y!!.^^::::::::::^^^^:::.:::!??77JB##YGG~J##################    //
//    #############################P!??JPPP?7P^Y?!:^^::::::::^^^^^^^^::::::::?G###B7J^J#GB################    //
//    ############################Y75BP5PPP5?5??57^:^::^^:^::^^^^^^^::::^^^:::^!7!~^!5#B#YB###############    //
//    ##########################GJ5##P5Y555PP55?GY7:!^:7^^::^:::::::::::::^^^^^^^~7~B#PB#5Y###############    //
//    ########################BP5B#G?Y?YJ5GGGBG55B5?!?^J~^^:^~^^^^^^^^::^:::^~~^^J!J#PG##J5###############    //
//    #######################BBB##5!??55GPY55YY55PP5YJJY?^^?PPY7~^::^^^^^:^^^^~^::!#GG##PJ################    //
//    ##########################BJ?P!5G#P~?J5PG5??~^!?JPG!77~^:~77^:::^^:::::^::~YY7?BBP5#################    //
//    ###################B###BG5YYGJ~Y5Y7JPP?Y?:^7^..::~~::...:::~7!!::^:::::^!7~~?7J5PG#GG###############    //
//    ###################PBBBG5#BJBY7GBP?B#Y7!^^^~!!~^:..:^~!!~^^^!?77^^^^:^^^^~!?YJYPBGY5################    //
//    ###################P?GPY?GP!YP~GB5PGG57~^!7~77??~::~7?7?~7!^~7YBJ77~~^~~!!!!75G5?7P#################    //
//    ####################J!YJ~~7!^7?!5PPPGBY7~::^~^^^^^::^^^~^::~7JGGJJPJYJ!~~!7!77!~?PBBB#####GG########    //
//    #####################Y!~~~^!JPPY7J5PGGG57^.:::::^~:::::::.:7YPPGJ5PP55PY7!!~~~!!?5GB#BGPYJP#########    //
//    #########BBBGP5J?77777!~~!JPGGGBGPY5PPGB#J:::::::^::::::::7BBPP55PGGBGPPG57~~~~~?YJJ7!~!YB##########    //
//    #########B5J7!~~~~~~~~~!YGPGBGBBBBGPGPPB&Y!^:::::^^::::::~J##PPGPPBGBBBBGPG57~~~^~!~^~!5############    //
//    ###########B5?!!~~~~~~~7GPPBBBBBBGPPBGPB&B7~^::~????7::^~~P##GPBPPGGBGBBGPPP5~!!!!!~!YB#############    //
//    ########BGGG?~~~~~~~~~~JPPPPGGGPPPPGBPPB#&G!^~^:^~^^^:^^^P###GPBGPPPPPPPPPPG5!!!!!!~!7?YGBGB########    //
//    ########GJ?YPG5!~~!!!~~YBGPPPPPGGGBBGPPP#&&B7:^^^::^^^:~P&&#GPPPGBGGGPPPPPGG5~~!!!~~~~^~!7?5########    //
//    ########GYJBBJ77!!7~~~~5GBGGGGGG5YJ?7~~~5####Y~:::::.^?B###P7!~!7JJ5PPGGGGBG5~~~~~!~!?Y55?JPB#######    //
//    #########PJ?J5P5PP7^!!~5PP5Y?7!~~~^!!~~~7PB#&&BJ^:.:7G&&#BP77!~~!~~~~~7?JYPPY!!~~~!~~P&&GJ5#########    //
//    GP#######B?7GBPGY??Y7^~~!!!~^^^!!!!!!~7J?JYPB##&B5YG####BGYJG7^!!!!!~~~!!!~!~~7Y?!~YY7JPJYB#######GG    //
//    J?G&#####5PYJGBGGB&Y~~!J7!7JJ7?~~7~!~Y?P#BGGBB###&&####BGPG#P!7~!?!!!!~7!?~J7^~YGPJ!B#BJJP#######BJY    //
//    5JJB#####B&PJY#####7?P#GYG##P#5~5J~?7##5PGBBB#B##BBB###BBBBGJGJ!G5^JY~!~~P57PY!~?G&5J#PJ5########YJ5    //
//    BY?YB&&&&&&#PJY###BY#&#B&&#B#&P?&J!GJB#BBGGGGBGBBPPGBGGBGGGGB#?5&Y^GB!5~~P&B5GB5?7YBG5J5#&&#####5JYG    //
//    #BY?YB&&&&&&#PJY####&&&&&&&##&#5#G!BGG#PBGBGGPGPGGGGPGPGGBGBP#YGB7Y#BJ&J~P&&&#B##BGPYJ5#&&&&&&#5JYG#    //
//    ##GYJJB&&&&&&#PJY#&&&&&&&&&#B#&BB&JYBBGP#GGPGPGGGGGGGGPGGGGBPGGGY5##PG&P~B&&&&&####PJ5#&&&&&&#YJYG##    //
//    BBGGY?JG&&&&&&#GJJB&&&&&&&&&#B##&#GYGPP55GGGGGGPPGGPPGGGGGG55PPGBG##B##P?&&&&&&&##5JP#####&&BYJYG#BB    //
//    GGGBB5J?5#&#####GYJP#&&&&&&&##B#&&##B5GPYYGGGGGPGBBGPGGGGGYYPG5##B&&#B#PG&&&&&&#BYJG#######GJJ5GBGPP    //
//    GBGGBBPY?JB#######PJ5B&&#######BBB######BB#&##############BBB###BBBBB########&#PJ5B&######5?YPBBGP5P    //
//    GGBGGGBB5J?P#&#&&&#BYJP##########BGGGGBBBB####&B####B#&###BB#BGGGGBB#BB######GYJG#&&&&&#GJJ5GBGPPGGP    //
//    GPGGGP5GBGY?JG&&&&&&#GYYPG###BGGB##BGGGGGGGGGGGB####BGGGGGGBGGGGBB##GGG#B#BPYYP#&&&&&&B5JYPBGPPGBBBB    //
//    PGG5PGP5PBBPY?YB&&&&&&#BGB##BGGGGGB###BBGGGBBB#######BBBBBBBBBB###BGGGG#B#BGB#&&&&&&#PJJPGP55GBBBBBG    //
//    PPGG55PGBGGGBPYJ5B&&&&&#B####BGGGGGGBB######BBB########BBB#B#BBGGBGGGGB######&&&&&#PJYPGP55PGGGBBGGG    //
//    5PPBBGGGBBBGGGBG5YYG##########BBBBBBBBBBGGGGGGB#B#####BGGGGGGGGGBGGGGG##########G5YYPGGGPGGGGBGPPPGG    //
//    P55GGGBBBBBBBBGGGP555PPG#&###BBBBBBBGGGGGGGGGB##B#####BGGGGGGGGBBGGGGBB###&#G5555PGGBBBBBBBBG5Y5PPPG    //
//    PGGPPPPPGGBBBBBBGGPPGGGGG##&#####BBGGGGGGGGBBBB######BGGGGGGGGBBGGBB#######GGBGGBBBB#BBBGGGGPPPPPGGG    //
//    BBBBBGPP5555PGGBBBBBBBBBBB#&####&&&####BBBBBBBB###GG#BGGBBBBB#############BGGBBBBBGGPPGGGGBBGGPPPP55    //
//    GBBBBBGGG5PPPGGGGGGGGGGGBB##&####&&&&&&##################&&&&&&&&#######&BGGGBBGPG55PGBBBBBBBBGP55GB    //
//    PGB#BBBPPPGGGBBBBBBBBGGGBBB#&####&&&&&&&###&&&&&#&&&&&&&&&&&&&&&#########BBBBBBBBBBB###BBGGGGGGGBB##    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PP is ERC1155Creator {
    constructor() ERC1155Creator() {}
}