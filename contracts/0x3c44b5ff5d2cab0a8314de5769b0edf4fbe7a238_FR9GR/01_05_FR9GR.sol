// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fake Rothko By 9GreenRats
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    Y555555555555YJJJ555555555555555555555YYYYYYYYY5555555555YJ5555555555555555555555555555YJ555555555555Y55555555555555PPPP    //
//    5PGGGGGGPPPPPPPP5555555555557~755555PP555PPPPPPPPP5PPPPGGP5GGGGGGGGPPPP5JJYPPPPP5555555?!P5PJ!75PPPPPPPPPGPGGPPPPPP5YPGG    //
//    PGGGGPP55555Y5Y^J5YYYYYYYYYYYJYYYYY555Y~~55555555?77775PP5YP5555Y555555J^^!55555YJJ55555YYYYJ??Y5YYYYYYYYYYYY5PGGBGY?Y5P    //
//    5PPPP55555YYYYY7JYYYYJJYYYYYYYYYJ?JYYYYJJYYYYYYYY55555555YJ57~YYYYY77YYYYYYYYYJJYYYYYYYJJJJJJJJJJJJJJJJJ???77?J5GBBY7JYP    //
//    55P5555555YYYYY5YYYYYJJYYYYYYYYY77JYYYYYYYYYYYYYYJYYY55YYJJYJJYYYYYYY?!!7YJJJJ!~7JJJ??JJJ!~JJYYYYYYYYYYYYYJ?!7JY5GGY77J5    //
//    55555YYY5YYYYYYYYYYYY?77YYYYYYYYY5YYYYYYYYYYYYYYJ^?YYYYYYJ?JJJ!!?YJYYJJJYYYJYYYJJJJJJJJJJJ?JJJJJJYYYYYYYYYJ?7??JJ5PJ!7?J    //
//    5555YYYYYYYYYYYYYYYYY7!755555YYYY5YYYYYYY5YYYYYYYYYYYYYYYJ?JJJ77?JJ??JJJYY?7YJJJJJJJJJJJJJJJJJJJJJYYYYYYJ??7777??YPJ!7?J    //
//    55P5YYYYYYYYY555555555555555J!J5555YYYYYYYYYYYYYYYYYYYYYYJ?JJYYYJJJ!!JJJJJ???J???JJ????JJJJJJJJJJJJJJJJJJ???77777J5J!7?Y    //
//    55P5YYYYYYYYY5555555555555555YY5YYJYYYYYYYYYYYYYYYYYYYYYYJ?JJJJJJJJJJ??J????????????JJ?JJJJJJJJJJJJJJJJJ????77777?Y?77J5    //
//    5555YYYYYYYY555555555555YYYYYYYYYY!YYYYYYYYYYYY!~?YYYYYYYJ?JJJ?????????????77??????J?7JJJJJJJJJJJJJJJJJ???J?77777?YJ7?JY    //
//    Y555YYYYYYYY55555555Y55YYYYYYYYYYYYYYYYYJ77YYYYYJYYYYYYYYJ?JJJJ7?????????????JJJ??????????JJJJJJJJJJJJJ????777777?YJ??JY    //
//    Y555YYYYYYYY55555555555YYYJ77?YYYYYYYYYYJ??YYYYYYYYYJ??JYJ?JJJJJJ???????????????77?77?????????????J?JJJJ????77777J5J?JJY    //
//    YY55YYYYYYY5555555555555555YY55555YYYYYYYYYYYYYYYJJJJ??JJ??JJJJJ?????77777777!~~!77777777???????????JJJJJ??77?77?JYYJJJY    //
//    YY555YYYYYY5555Y5Y555555555555555Y5YYYYYYYJ7?YYYYJJJJJJJJ??J??????77777777777!!!!777777777???????????JJJJJ??????JJYYJJJJ    //
//    YY555YYYYY5555YY555555555555J!!Y5Y55Y^~555?:^YYYJJJ?JJJJJ?7????????!^^!77777777777777777777??????????JJJJJJ?JJ?JJJYYYYJJ    //
//    YY555YYYYY555Y55555555555555YJJY55555YY55YYYYYYJJJ?7JJJ?J?7???J????7~~7777?7!!77777777777????????????JJJJJJ?J?JJJJYYYYJJ    //
//    YY555YYYYY5555555555555555555555555555YYYY?7JJJJJJJJJJJJJ?7J???????????7????777777777777?????????????JJJJ????JJYJJJY5YJJ    //
//    YY5P5YYYY55555555555555555555555Y?555YYYYJ!~?YJJJJJJJJJJ??7?????7???????????777777777777????????????JJJJJ???JJYYYJJY5YJJ    //
//    555P5YYYY5555555555555555555555555555YYYYYYYYYYYYYYYJJJJJ77?????JJJJJJ??!???7777777777777????????????JJJJ??JJYY5YJJY5YJJ    //
//    55PP55YYY5555555555555555555555555555J?YYYYYYYYYYYYYYYJJJ77??77?JJJYYJ??77777777777777?7?????????????JJJJJJYYYYYYJJY5YYY    //
//    555555YYYY555555555555555555555555555?!Y55555555YJ5YYJ?J??7??77?JJJJJ???7777777777777??7??????????????JJJJJJJYY5YJJY5555    //
//    55555YYYYY5555555555Y5555555555555555555JY555555YYYYY?^?J?7?????JJJJ!^~???77777777777??7?????????????JJJJJJJJJY5YJJY5555    //
//    55555YYYYYYYY5Y5555YY555555555555555555Y!?55555YYYYYJJ?JJ??JJ?7??????77???7??777777777??????????????JJJJJJJJJY55YYY55Y55    //
//    55555YYYYYYYYY555555555555555555555555555555YYY5Y???YJJJJ??J?7:~??7!7????????77?7???????????????????JJJJJJJYYY555555YYY5    //
//    55555YYYYYYYYY555YYY555555555555555555555555!7555YYYYYYJYJ?JJJ????!~7JJJJJ???????????????????????JJJJJJJJJYYY5P5555YJYY5    //
//    55555YYYYYYYY55555YY555555555555555555555555555555555JJYYYJY??JJJJJJJJJJ????????????????????????JJJJJYYYJJYYYP55555YJJY5    //
//    55555YYYYYYYY55555YY5555555555555555555555555555?Y555?J55YY5J?YYJ?JJ??????????????????JJJJJJ??JJJYYYYYYYYYYYY5YYYY5YJJY5    //
//    55555YYY55YYY55555YYY5555555Y5555555555555555555YY5555555YJ555YJ??J?????77?????????JJJJJJJJJJJJYYYJYYYYYYYYYYYJJJY5YJJY5    //
//    PPPP5YYY55YYYY5555YYYY5555555555555555555555555Y55YYYYYYYYJYYJJJJJJJ???????????????JJJJJJJJJJJYYYYJJYYYYY5YYYYJJJY5YJJY5    //
//    5PPPPGP555YP#P5555YYYYY5555555555555555555555YYYYYYYJYYYYYJYY??YYYJJJJJJJJJJ??????JJJ5Y5555YJJJJJJJJYYY55555YYJJJY5YJJY5    //
//    5PB#B#&&#[email protected]&5555YYYYY5555555555555555555555555YYY555YYYYJYY5YYYYYYYYYYYJJJJJJJJJJJJ5555555JJJJJJJJYYY5555Y5YYYYY5Y?JYY    //
//    55G#@@@@@@@@@@#5YYYYYY5555555555P555555555555555555555YJ5YJYJ55555YYYYYYYYYYYYYYYYYYY5555555JJJJJJJYY5555YY555YYYY5Y?JJY    //
//    55PPB#&@@@@@@@@#G5YYYYY555555555555555555555555555555555555P55555555YYYYYY55YYYYYYYYY5555555JJJJJJYYYY5555555555YY5YJJYY    //
//    55PP5YY5GB#&@@@@@&BP5YY55555Y5555555555555YY5555555555PB#&&&#BP55555555555555YYYYYYYYY555555YJJJJJJYYY55555Y5555YYY5PGPP    //
//    55PG5YYYYYJY5G&@@@@@&#BP555Y5555555555555555555555555G&@@@@@@@&G5555555555YYY555YYYYY5555555YYYYYYYYY5555Y5G#PYYYYYYPGPP    //
//    55PG5YJYYYJJJJYP#&@@@@@@&#BP5555555Y5YY555555555PPPPP#@@@@@@@@@#555555555YY555YY5Y5555555555555YY55555YYY5#@&P5PGGGGPP55    //
//    5PGG5YJJJYYJJJJJY5B&@@@@@@@@&#[email protected]@@@@@@@@@&P55555555555555555555YY555Y555YY5YYYYY55G&@@@&@@@&####P5    //
//    55PG5YJJYYYYYJJJJJJY5B&@@@@@@@@&#GPYYYYYYYYYYYY5555P#@@@@@@@@@@@#P555555555555555555YJJJYJ?JYYY55PPGGB#&@@@@@@@@@@@&##P5    //
//    55PG5JJJJY5YYYJYYYYYYYPB&@@@@@@@@@@&BPYYYYYYYYYY5555PG&@@@@@@@@#PPPP5555555P55555555Y7?????YPGB#&@@@@@@@@&&&&&####BG5PP5    //
//    55PG5YYJJJJYYYYYJJJYY5YY5PB&@@@@@@@@@@#[email protected]@@@@@@&5Y55555555555Y5YYYY5P5YY5PB&@@@@@@@@@@&#GGPPPPP555YY55PP5    //
//    55PGPYYYJJJJYYYJJJYYYYYYYYY5G#&@@@@@@@@@@@@@@&#BP5PPGB#@@@@@@@&BP55555555PPGGGGGG#&&@@@@@@@@@@@@@@#BGPPPGGGBBBGGGPPPPP55    //
//    55PPP5YYYJYYYYYYYYYYYYYYYYYYYYPB#&@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@&#B##&&&&@@@@@@@@@@@@@@@@@@@@&&#BBBBBBB########BBBBGP55    //
//    5Y5GGPP55YYYYYYY5555555555555555PGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GPP5B######################BGP55    //
//    YY5GBBGGGPPPPGGGGGGGGGGGBGBBBBBBBBBBB##&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PY?777?B######################BGP55    //
//    Y5PB######################################&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&P!7777??B#######################BGGG    //
//    55PB#######################################&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##########P77?7???B###########################    //
//    5PGB#######################################&@@@@@@@@@@@@@@@@@@@@@@@@@@@&############P7??????B#######################BBBB    //
//    5PGB########################################&@@@@@@@@@@@@@@@@@@@@@@@@@@#############P??????JB######################BGP55    //
//    55PB#########################################@@@@@@@@@@@@@@@@@@@@@@@@@&#############P?JJ?JJJB#######################BGB#    //
//    Y5PB##########################################@@@@@@@@@@@@@@@@@@@@@@@&############B#GJJJJJYYB#######################BG##    //
//    Y5PGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#@@@@@@@@@@@@@@@@@@@@@@&BB##########B#GJYYYYYYB#######################BG##    //
//    555555PPPPPPPPPPPPPPPPPPPPPPPPPPPPGPPPPGGGGGGGB&@@@@@@@@@@@@@@@@@@@@&#BB#####B####B#GJYYY55YB##B####################BG##    //
//    55P5PPPPPPPPPPPPPPPPPPPPPPPPPPGGGGPPPPGPGGGGGGB&@@@@@@@@@@@@@@@@@@@@#BBBBBB##BBBBBB#GYYYYYYYB####B#B################BG##    //
//    55PPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB#@@@@@@@@@@@@@@@@@@@@&#####BBBBBBBBBB#GYYYYYYYB#B###B#####BB##########BG##    //
//    55PB##########################################&@@@@@@@@@@@@@@@@@@@@&#B###BBBBBBBBBB#GYYYYYYYB#######BB#BBBB#B#######BG##    //
//    55PB##########################################&@@@@@@@@@@@@@@@@@@@@&B####BBBBBBBBBB#GJYYYYYYB#####BBBBBBBBBBBB#B####BGGG    //
//    55PG##BGGB####################################&@@@@@@@@@@@@@@@@@@@@&#######B##BBBBBBBPPPPGGGB####BBBBBB##BBBB#######BGP5    //
//    55PG##PY5PB###################################&@@@@@@@@@@@@@@@@@@@@&###########BBBBB#############BBBBBBB#BBB########BGP5    //
//    55PG##PY5PB##################################&@@@@@@@@@@@@@@@@@@@@@@############BBBB#############BBBBB###BB#B#######BG55    //
//    555G##P55PB#################################&@@@@@@@@@@@@@@@@@@@@@@@&##########B#B###############BBBB####BBBB#######BG55    //
//    555G##PY5PB#################################&@@@@@@@@@@@@@@@@@@@@@@@&############################BBBB####BBB########BGP5    //
//    555G##PY5PB################################&@@@@@@@@@@@@@@@@@@@@@@@@@############################BBBB#B##BBBB#######BGP5    //
//    Y55G##PY5PB###############################&@@@@@@@@@@@@@@@@@@@@@@@@@@&###########################BBBBBB##BBB########BGP5    //
//    Y55GB#BGGB###############################&@@@@@@@@@@@@@&&&@@@@@@@@@@@@###########################BBBBB##############BGP5    //
//    Y55GB##&#################################&@@@@@@@@@@@@&##&@@@@@@@@@@@@&##########################BBBB###############BGP5    //
//    Y5PG#####################################@@@@@@@@@@@@&####@@@@@@@@@@@@&###########################BBB###############BGP5    //
//    55PG####################################&@@@@@@@@@@@@#####&@@@@@@@@@@@&############################B################BGP5    //
//    55PG####################################&@@@@@@@@@@@######&@@@@@@@@@@@##############################################BGP5    //
//    55PG####################################&@@@@@@@@@@&#######&@@@@@@@@@@##############################################BGP5    //
//    Y5PB####################################&@@@@@@@@@&########&@@@@@@@@@&#############################################BBGP5    //
//    55PB####################################&@@@@@@@@&##########&@@@@@@@@##############################################BGPP5    //
//    Y5PB###################################&&@@@@@@@&############@@@@@@@@###############################################BGPP    //
//    YY5B##################################&@@@@@@@&&#############&@@@@@@@###################################################    //
//    YY5B#################################&@@@@@@@@&###############@@@@@@@&##################################################    //
//    YY5B################################&@@@@@@@@&###############&@@@@@@@@##################################################    //
//    YY5G################################&@@@@@@@&################&@@@@@@@&#########################################B###BGGGP    //
//    Y55B################################&@@@@@@&##################@@@@@@@&########################################BGB##BP555    //
//    Y55B################################@@@@@@&###################&@@@@@@&#####B#BBBBB###BBBBBBBBBBBBBBBBBBBBBBBBBBGGGGPP555    //
//    YY5PGGBBBBBBGGGGGGGGGGGGGPPPPPPPPP5P&@@@&GPPPPPPPPPP5PPPPPPP55P#@@@&&PY55555555555555555555555555P5P55555PPPPPPPPPPPP555    //
//    YYY5PPPPPP555555555Y5555YYYYYYYYYYY5#@@#5YYYYYYYYYYYYYYYYYYJYJJ5&@@@#YJJJJJJJJJJJJJJYYYYYYY55555555555555555555PPPPPPP55    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FR9GR is ERC1155Creator {
    constructor() ERC1155Creator("Fake Rothko By 9GreenRats", "FR9GR") {}
}