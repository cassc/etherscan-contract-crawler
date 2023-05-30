// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: It's Just Me
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    #######BPPPPY?PGBB######################################################################################################################################################################################    //
//    BB#####BPPPPY?PGBB######################################################################################################################################################################################    //
//    BBBBB#BBPPPPY?PGBB######################################################################################################################################################################################    //
//    ###BBB#BPPPPY?PGBB###################B############################################################################################################################################################B#####    //
//    ####BBBBPPPPY?PGBB######################################################################################################################################################################################    //
//    ##B###BBGPPPY?5GGB########B#####################################################################################################################&&&#####################################################    //
//    ######BBGPPPY?5GGB#######BB#########################B###########################################################################&&&&&&&&&######&&#######################################################    //
//    ######BBGPP5Y?5GGB#######BB#######################&#######################################################################&&&&&&&&&&&&&&&&&###&&#####&&#################################################    //
//    BBBB###BGP55Y?5GGB########################################################################################################&&&#&&&&@@@&&&&&&&&@@&&&&##&&&&&&&&&&&########################################    //
//    BB#####BGP55Y?5PGB######################B##########B################################################################&&####&&&&&@@@@@@&@&&&&@@@&&&&&&&@@&@@@@@@@&&&&&&&&&&###############################    //
//    BBBB####GP55Y?YPGBB#####B#########################################################################################&&###&&&&&&&&@@@@@@@@&&&&@@&&&@&&&@@@@@@@@@@@@@@&@@&&&&&&&&###########################    //
//    BBB#####GP5557YPGB#############################################################################################&&&###&&####&&&&&&@@@@@@&&&&&&&&@@&&@@&&&&&&&&&@@@@@@@@@&@&&&&&&&########################    //
//    #####BB#GP5557YPGB############################################################################################&&#&&&&&##&&#&&&&&&&@@@@&&&&&&&&&@@@&&&@@@@@@&&&&&&&&@@@@@@@&&&&&&&&######################    //
//    ##B###B#GP5557JPGB#################################################&#B########################################&&&&&&######&&&&&&&@@&#B#&&&@&&&&&@@&&&@@@@@@@@&&&&&&&&&@@&&&&&&&&&&&&&###################    //
//    B##B##BBGP5557JPGB##########B##############################################################################&&&&&&&&########&&&&&@@&#BBB#&&@@&&&&&&&&&@@&&@@@@@@&&&&&&&&#&&&&&&&&&&&&&&&#################    //
//    BBBBBBBBGP555?JPGB#####BBB##B#############################################################################&&&&&&&&&#######&&@&&@@&####&&&&&@&&&&&&&&&&@@&&&&@@@&&&&&&&######&&&&&&&&&&&&&###############    //
//    BBBBB#BBGP5557JPGB######B################################################################################&&&&&&&########&&&&&&@@@&&&####&&&@@&&&&&&&&&&@@&&&&&&&&&&&&&#########&&&&&&#&&&&##############    //
//    BBBBB###GP55Y7?5PBB####BB###############################################################################&&&&&&#########&&&&&&@@@@@&&&&&&@@&@@&&&&&&&&&&&&&@&&&&&&&&&&&##BBB#####&###&###&&###########BB#    //
//    BBBBB###G55YY7?5PGBB######BB###############################BBBGGGGGGGBB####&###########################&&&&&&##&&###&####&&&&@@@&@@&&&@@@@@@@@&@@&&&&#&&&&&&&&&&&&&&######BGBBB###B######&&&############    //
//    BB#BBB#BG5555??5PGBB######B##############################BBGGGPPPPP55Y555PGGBB#######################&&##&##&&&&##&#######&&&&&&&&&&&&&&&&@@&&&&&&&&&&&&&&&&&&#&&&&&######BBGB##########################    //
//    #B#BBB#BG55Y57?5PGB#####################################BGBBGGGPPPPPYYYYYYY5555PGBB##################&##&#&&&&&##############&&&&&&&&&&&&@&&#B###&&&&&&&&&&&&&&#&&#&##&##BBB#BB##&####&&&#&#############    //
//    ####B###G55Y5?75PGB#####################################BGBBGGGGPPPGP5YYYYYY555555PPGBB##################&&#&&###&###BBBBB########&&&&&&&&&#GGGGB####&#######&&###&&&#############&&#&&&&##&############    //
//    BBBB####B55YY??5PGB##BB###BB###########################BGPGBBGGGGPPPPGP55555Y55555555PPGBBB#######BPG###&&##&&&&&&###BBBBB#######&&&&&&&&#GGP55PGBBB##&#B######&####&&#####&#####BB#&&&&&&&#############    //
//    BBBB#BBBG55YY?75PGB###BB###############################BGPPBBBBBGGGPPPGGGGGGGGGGGGPPPPPPGBBBBB##B5JYBBB#&#&&&&&&&&###BBBBB#BB#######&#&&BPY555Y555PGBBB#&#BBBB#######&&###&&&&&###BG#&&&&&&&############    //
//    #BBB#BBBG55YY?75PGBB###B#################BBB###########BGGPGBBBBBGGPPPPPGGGGGGGBBGGPPPPGGGBBBGBG55PBBPG###&&&&&&&&&#BBBB##B###BBB##&###BP5?JJJJ?JJY5GGGGB#&#BBBBBB####&#####&&&&&###GB&&&&&&&###########    //
//    ##BB##BBB55YY?7YPGBB##BB###############BBB#############BGGGPGGGPGGPGB###&&&&&#BBBBBGP5PGPGGGGBP?JJPG55GB##&&&&&&&#BBB#&#####BBBBB###BBBGYJ!!77777??JYPGGGB#####BBBB#############&&&##BB&@&&&&###########    //
//    ##BB##BBB55YY?7YPGBBB##B#############BBB##############BGGGGPPGGGGGB&@@@@@@&&&@@@@&&&&BBGGPGGB5!777PY5PP##&&&&&&####&&&&&&####BBBB##BGGBPJ?!!~~!!7?77?JYPPPGB#&#B#BB###############&&#&BB&&&&############    //
//    BBBBBBBBB55YY?7Y5GBBB#########B#####BBB#BBB##########BGGGGGGPPBBB#&&@@@@@@@@@@@@@@&&@@@&&BGGY!!7??JYY5B#&&&&#&&&#&&&&&&&&&###GGBBBBGPPGPJ?7!~~~!!7??7?J55PPPB#&#B##B##&&&#BBB#B######&&B#&&#############    //
//    BBB#BBB#BP5YY?7Y5GB####BBB#####B###BBBBBBBBB##BB#####BGGGGGGGPP#&&&@@@@@@@@@@&&&@&&&@&&&@@@P~!!?JYYP5P#B&&&##&&&&&&&&&&&&&#BGGBBGGP55YPGJ?7!~~!!7??JJJJY555PPGB#BB##B#&&&&&BBGGB######&&#&&#############    //
//    BBB#BBB#BP55Y?7Y5PBB###BBB#BBB###BBBBBBBBBBBBBB####BGGGGGGGGGPPP&&@@@@@@@@@@@@@@&&&&&&@@@&&7!~7??7?JJBBB&&&#&&&@&&&&&&&&#GGPPGGPP5JYYY5GY?777!777?JYY555P55555PB#B#####&&&&&#GGGB####B#&&&&#############    //
//    BBBBBBB#BP55Y?7Y5PB##BBBB#BB###BBGB#BBBBBBBGBB####[email protected]&@@@@@@@@@@@@@@@@@@@&&##G~7~~?!~!7JPB&#&&&&&@@@&&##&BG5YY5GPP5J???JYJP5J777777?Y7^~?Y5PPPP555PB#######&#####BGGB###BB#&&&#############    //
//    B###BBBBBP55Y?7Y5PG##BBBBBB###BGGBBBBGGGGBGGGGBGGGGGPPGGBBGGGBGGG#&@@&&&&&#####BBBGGGGBBB#B~77^?!!7?JJBBGB##&&&&&&BG#GPYJ?5P5J5J777??JJYYYJ?7777?Y?7!7!?Y55Y5P5PPB####&&&&##B#&BBB####BB#&&&############    //
//    BBBBBBBBBP55Y?7Y5PGB#BBBBBB#BGGGGGGGPGGGGGGGGGGGGGGGPGGGGBBBBBBGGB&BGGGPPP555YYYJJJJYPGGBBB!~7!!!~~7~YGGGBB##&&&&&BG5YJJ?Y5YY?Y????J77~7JYYYJJ?77Y5YJ?7?JJY?JYY5PGB#&##&&&###BB&BGB######&&&############    //
//    BBBBB#BBBP55YJ7YYPG#BBBGGGGGPPPPPPPPPPGPPPPPPPPPPPPGGGGGGGGBBBBBGBBGPPP555YYYYJJJJJJY5P5PB&7~!~^~7J!~PP5GBB####&&&&BJJ?7JJJJ??5???YJ!7^^~7YJ?JYJJJJ5P5YYJ?JY????J5G#&&###&&#&#GB&#B####&##&&############    //
//    BBBBBBB#BP55YJ7YYPGGGGGGGGGGGGGGPPPPPPPGPPPPPPPPP5PPPBGPGPPPGBBBBBBGPP55YYYJJ???????JYY5PB&Y~!~~^^77!5YPBB##[email protected]&&#GJ??Y?J???J??JY5YJ???77?777JJJJYY5PPPYJJ77777YYG#&&#####&&#B#&#####&&###############    //
//    #BBBBBB##P55YJ7YYPPPGGGGGGGGGGGGGGGGGPPPGPPPPPPPPPPPPPGGPPGGGBBBBBBBP555YYJJ??777777???JYG#B7~~~~~!!?J?GB##P?77?G&&&&GYYJJJ???????JYPG5YJ??777?7!~~7?JJ5PGPY?777!Y?5B#&######&&#######&&&&&#############    //
//    BBB#BBBB#P55YJ7YYPPPGGGGGGGGGGGGGGGGGPPPPGPP55PPPPPPP5PGPGPPPGGBB#B#GPP5YYJJ??777777777?JYG&B?~~~~!7??JB#BP?!7777P&&&&PYJJJ??????JJ77J5PGG5YJ?7~^::^~!7?JYPGG5J7?J?JBB&&######&&######&&&&&#############    //
//    BBBBBBBBBPP5YY?Y5PPPGGGGGGGGGGGGGGGGPPPPPPPPPP5PPPPPP55PGPPPGGGBBB##BPPP55YJJ???77777777??JPBPY?!!7???Y#BP?!!!77775#&&&#P555PP5YYY!~~~!JJYPPGPY?!~^^^^~!7?JY5GG5YYJYBB#&&###&&#&&#####&&@&&&############    //
//    BBBBBBGGG5P55Y7J5PPGGGGGGGGGGGGGGGGPPPPP5PPPP555PPPPP555PGPPGGGBBB###BGPPP5YYJJ??77777!!77??YYYYY5Y???5BPY777!!!77?Y&&BG&##BBBGGGGJ???7??777JYPG5J7!~~~~!??JJYPGGPYJGBB##&##&&&&&&#&#&&&&&&&############    //
//    BBBGGPPPP5P55Y?Y5PGGPGGGGGGGGGGGGGPPPPPP555P55555PPPPPP555GGPGGGBB##BBGGGGP55YJJ??7777!!!77????JJJJJ??YP5?77!!!!!7?J5&#PB&&&&###BBBG5Y?77!!!!!!?5GG5J777??JJJYYYPGG5GBGBB&#&&&&&&&&&&&&&&&&&############    //
//    GPPPPPPPPPP55Y?J5PGPPPGGGGGGGGGGPPPPPPPP5555PPY555PPPPP555PBGPGGGB###BBGGGGP55YJJ??777!~!!7??77?JJ?J?7JJY?77!~~~!7??5&&&#GGPGB###&####GYJ77!~^^^~!7YPPYJ?????J?Y5YPGBGPGB##&&&&&&&&&&&&&&&&#############    //
//    PPPPPPPPPPP555JY5PGPPPPPPPPPPPPPP55555555555PP55555555555P55BBPGGBB##BBBGGGGP55YJJ??77!!!!77777?JJJJ???J???7!~~!!77Y&&BP5YYYYY55PB##&&&&#G5J7!^^^~~!7?Y55YJ?7??YJJY5BBGGGB##&&&@@&&&&&&@&&&#############    //
//    PPPPP555PPPP55JY5PGPPPPPPPPPPPP55555YYYYYYYY5P555YYY55555555PBBPGGGB##BBBGGGPP55YJJ??77!!77777?JYJJ??J?J???7!!!!!!5&BP555YY55555YY5PB#&GJJ5PG5?7!~!!7?JJJY55YJJJJJJY5PGGGBB##&&@@&&&&&&@&&##############    //
//    PPPP555555PP55JYPGGP55PPPPPPPPP5555YYYYYYYYYYP5YYYYYYYYYY5555PBGPGBB##[email protected]G!~^!?YPBPJ????JYYJJJY5P5JJJJJJJYPGBB##&&@@&&&&&&&&&##############    //
//    PP5555555PPPP5JY5GGP55PPPPPPPPP5555YYYYYJYYYY5P5YYYYYYYYYY555PPGGPGB####BBGGGPP55YYYYJJJ?????JJY5YJJ?????77!!!!77B&555PGPPPPPPPGGGGGGGG7~!!!??JG#G5YYJJJ????JY5P5J????JJYPGB##&@@&&&&&&&&##B############    //
//    55YYYYYYY5PP557J5GGP5PPPPPPPPPPP555Y5YYJJY5YYY55YYYYYYYYYY5555PPGPGBBB####BGGGGP55YYYYYYYJJJJJYY5YJ????777!~~!!775&BPPPGGGGGGGGGGGGGGGBG?~!!~!!75#&BPYJJ?????JJY55J7!77??JJ5GB#&&&&&&&&&&############B##    //
//    5JJYYYYJJ5PPP57J5GGP5PPPPPPPPPPP55YY5YYYYY5YY5555Y55YYYYYY55PPPPPGGGBB###@#BGGGGPP555555YYYYJYYY5JJ???777!~~~~!!775##GGGGGGGBGGGGGGGBBBBB57!~~~~!?5#&#PYJJJ?JJ?JYY5Y7!!777JY5GBB#&&&&&&&###############B    //
//    YJJJJJJJJ5PPP5JYPGGPPPPPPGPPPPPP55Y55YYYY55555555Y55YYYYYY555PPPPGBGBB##&@&BGGGGPPP55555YYYYYYY55JJ???777!~~~~~!777?G##BBBGGGGGGGGGBBBBBB##5?77!~~^~?5G#G5YJJJJYJJJJYY??7??Y5PGGBB#&&@&&#####B#BB####GY?    //
//    JJJJJJJJJ5PPP5?J5PGPPPPPGGPPPGGP555P5YYYY55555555555YYYYYY555PPPPPGGGB##&@&#BGGGGPP55555YYYYYYY55Y?????77!!~~~!!!777?JP###BGGGGGGGGGGBB#&&&&G5J7!~^^~~!75GG5J?JJJJ????JJJJJY5PGGGGB#&&&&##BBBBBBB##GJ777    //
//    JJJJJJJJJ5[email protected]@&#GGGGPP555555YYYYYY55J?????7!!!!!!!!!777777?YPB############BP5PGGBB5?7!!!!7~~!?Y5Y?77777777?JYYY5PPPGGGB#&&&#BBBBB###BY777??    //
//    JJ????JJY5PPP5?J5PGGGGGGBGGGGGP55PGP55YY555555555555YYYYYY5555PPPPPGBGGGG#@&&BGGGGGPP5555555YYYY5J????77777777777!!!!777?JY55PPPPP55YYJ??J5GGB&&BYJ??77!~~~!7JYJ77777??JYY555PPPPPGGG###BBBBBB##P?777???    //
//    JJ?????JY5PP55?J5PGGGBGBBGGGGGP5PGGP55555PP55555555PYYYYYYY555PPPPPPGBGGGG#@&&BGGGGPP55555555YYY5J??7??777777777777???JJJJJJYJJJ??????7??J5GB#&&&#B5J?77!!!!77?JJ?7777?JYYY55PPP5PPGGGB#BBBBBBBY777????J    //
//    JJJ????JYPPP55?J5PPGBBGBBGBBBG5PGGPPP5555PP555P5555PYYYYYYY5555PPPPPGBGGGGG&@&&BGGGGPP555Y5555YYYJ???????7777777??????77777JY?77??JJ??7?J5PB##&##BB##GYYJJ?JJJ??7???7???JYYYY5PP555PGPGBBBBBBBJ7????JY55    //
//    JJJ???JJ5PPP55[email protected]&#GPPGGGP55555555Y5J?7777???777???J??JJJ?????J55Y?7????77?J5GB##&##BGB##&#P5YYYYYJ???????JJYYYY55PP55PGGPGBBBBBY???JYY555Y    //
//    YJJ??JJJ5GP55Y?J55PGBBBBBBBBPPGBGGGGPPPPPP55PPP555555YYYYYY555555PPPPGBGGGBGP#@@#G5PPPGPP555PPP55YJ???7?JJ??JYYYJJ?YYJYJJYJY5555YJ??7~!?Y5GBBB#&&&##&&&&&#P5YYYYYJYJJJJJJYYYYY55PPPPPGGGBBBBY?JJJY5555YY    //
//    5YJJJJJY5GP55Y?J55PGBBBBB#BGPGBGGGGGPPPPPPPPPP5555555YYYYYY5555P5PPPPGGGGGGGG#@@@&G55PPPPPP55PPPPPYJJJ?JJJJJYYY55P5YY?JY55Y555555PY?7!7JY5GBBBB##&&&@&&&@@#P55YYJJJYYYYYYYYY555555PPPPGGGBBP??JJY5555YYY    //
//    55YYJYYY5GP55Y7Y55PGBBBB#BGPGGBGGGGGGPPPPPPPPPP555555YYYYY5555PPPPPPPPGGGGGGP#@@@@&G555PPPPPPPPPPPPYJJJJYYYJJJJ??JPPP5YJ?JJY55PPPGP5YJY55PGBBBBBB#&&&&@@@&@&G5YYYYYYYYYYYYY5P55555PPPPGGGBG?7JJY555555YY    //
//    PPP5YY555GP5YY?Y55PGBBBBBBGGGBGBBBGGGGPPPPPPPP5555555YYYYYYY55PPPPPPPPPGGGGGP#@@@@@@#PY5PPPGGGGGGGGPYJJJYYJJJYJJJJYY5GP5YYJ?YPGPPPBBBBBBBBBBBBB##&&&&&&&&&&&#G5YYJYJJJJJJY55PPPP55PPPGGGBG?7?JYY5555YYYY    //
//    PPPP55PPPGPYYY?Y5PPGBBB#[email protected]@@&&&&&#555PPGGBBBBBB5YY?JYYYYYYYYYJYYY5PGPP5Y55YYPB###BBBBBBB#&#&&&&&&&&&&&&&#BP5YJJJJJYJY5PPPPPPPPPGGGB5?7??JJYY5555YYY    //
//    PGGGGP5PGBPYYY7Y5PPGBB#BBGGBBBBBBBBBGGGPPPPGPP55555Y5YJJJJYY5PPPPPPPPPPPGGGGGG&@&&&&&&&#GP55PPGGBBBBG5JJJ?JJYY55PP55Y5JY5PGGPP55PGBBBBBBBBB##&#&&&&&&&&&&&&&&##BP5YYY5YYY55PPPPPPGGGGBGY????JJYYY555555Y    //
//    GGGGGGGPPGPYYJ7Y5PPGBB#[email protected]@@&&&&&&&&#BGPPGGPPPPG5YYJJ?JJJY5PGGGP55555PGGBBBBBBBBB#####&##&#&&&&&&&&&&&&###BGP555555PPPPPPGGGGBBP?7??????YYYY555555    //
//    GGGGGGGGGGPYYJ7J55PGBBBBBBBBBBBBBBBBBGGPPGGPPPP5P555YYYJJJJY5PPPPPPPPPPGPGGGGPG&@@@&&&&&&&&&&&#BGGGB#&#G5PYJJJJJJYYPGBBBGPPPPGGBBBBB#######&&###&&&###&&&&&&&&###BGP55PPPPPPPGGGGBBB5?????J???JYYYY5JJ55    //
//    GGGGGGGBBBPYYJ7J55PG#BBBBBBB#BBBBBBBBGGPGGGPPPPPP555YYYJJJJY5PPPPPPPPPPPPPPGGPG#@@@@&&&&&&&&&&&&&&&@@&#BBGGP55555555PPGBBBBBBBBBB##########&####&&&#&&&&&&&########BGPPPPGGGGGGBBBB57???????JYJJJY555Y55    //
//    BGGGGGGBBBG5YJ!J55PG##BBBB###BBBBBBBBGGGGGPPPPPPP5555YYJJJY5PPPPPPPPPPPPPPPPGGPB#@@@@&&&&&@@&&&@@@@#GPPPGGGGGGGGGPPPPPPGGBBBBBB###########&&###&&&###############B##BBGGPGGGBBBBBB57????????JYYYY55YY555    //
//    BGGGGBBBBBG5YY?J55PG#BBBB###BBBBBBBBBGGGGGPPPPPPP5555YYYJYY5PPPPPPPPPPPPPPPPPGPGB&@@@@&&&&&&@@@@@#P5555PPPPGGBBBBGGGGGBBBBBBBBBBBB########&###&&&&&&##################BBBBBBBBBBB5?????????JJYYJJYYY5555    //
//    GBGGGGBBBBG55Y?Y5PPGBBBB###BBBBBBBBBBGGGGGPPPPPPPP5555YYY5PPPPPP5P5PPPPPPPPPPGGPB#&@&@@@&&&&&&@&GYYYY555PPGBBBG###BBBBBB#BBBBBBBBB#######&###&&&&##BB############&&&#####BBGGGP5?!!!777????JJYY5YJYY5555    //
//    GGBGGGBBBBBP55JYPPPGBBB####BBBBBBBBBBGGGGGGPPPPPPP5555555PPPPPPP5P5PPPPPPPPPPPPPBB&@&&@@@@@&@&B5YYYYYYY5PBBGGGB#BBBBBBBBBBBBBBBBB#######&&#&&####BB############&&&#BGPYYJ?7!!~~^^~~^~~~~~~~~!!7?JJY55555    //
//    GGBBBBBBBBBPP5Y5PPPGBB####[email protected]@@&&&&@@&PYYYYYYYY5GBGPPGBBBBBGGBBBBBGGGGBBBB#######&#&&######BBBBGGGPPPPY?J?7~~^^^~!!!!!~~~~~~~~~~~~~~~~~~~~~!7????    //
//    GGBBBBBBBBBPP5Y5PPPGBB########BBBBBBBBBGGGGGGPPPPP55P5PPPGGGGPPPPPPPPPPPPPPPPPPPPBB&@@&&&@@B5YYYJJJJ5GBP55PGBBBBGGGGGGGGGGGGGGBB#######&#&#GGBG5?7!!~~^^~~~~~~!!~^^~!!!!!!!!!!!~~~~~~~~!!!!!!!!!~~~~!777    //
//    GGBBBBBBBBBPP5Y5PPPG###########[email protected]@@@@&PYYYYJJJ5GGG555PGBBBBGGGGGGGGPPPPGGGBB######&##57~^^^^^~~~~~^~7!!~~~~~~^^^^^^^^~~!!!777!!777777!!!!!!77!!~~~!!    //
//    GBBBBBBBB#BPPPY5PPPG#BGGBB#####BBBBBBBBBGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555PPBB&@@@#PYYYJJJ5GGP5555PGB#BGGGGGGGGGP55PPGGBB######&&B?YBBPJ~^^^:::^^^^~~~~~~~^^^^^^^^~!!!!7777777777777!!!!!!!~!!!!!!    //
//    GGBBBBBB#BBP5555PPPGPJ?JJYYPB####BBBBBBBBGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPP555PPGB#@@#P55YYY5PGP55555PGB#BBGGGGGGGPP55PPGGB########&#7J#BBBBG57^:^^:::^~~~^^~~^:^^^^^~!777777777777!777!!!!!777!~!!!!!    //
//    BBBBBBPYJ???JJJJJY5PY7777!!7JG######[email protected]&P55555PP555555PGGB#BBGGGGPGGP555PPGGB########&&P?G#GGBGGBBP?~~~!~~~~!~~~~^^~~~~^~~7777??77777???7?77!!77!!!77!!!!    //
//    BGP5J?777!!!!7777?YJJJJJJ??JY5#######BBBBBBGGGGGGPPPPPPPPPPPPPPPPPPPPPPPP5555PPPPPGGB&BP5PPPPPP55555PGBB#BBGGGGGGGP555PGGBB######&####!?BBGGGGGGGGG57~~!!~~~~~!~~~~~~~~!777777???????J??????77!!!!!77!!!    //
//    ?777777!~~^^^~~!!7JJ???JY5PPGB#######BBBBBBGGGGGGGPPPPPPPPPPPPPPPPPPPPPPP55555PPPPGGGBBPPPPPPP5555PPGBB##BBGGGGGGP555PGGBB####                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract jm is ERC1155Creator {
    constructor() ERC1155Creator() {}
}