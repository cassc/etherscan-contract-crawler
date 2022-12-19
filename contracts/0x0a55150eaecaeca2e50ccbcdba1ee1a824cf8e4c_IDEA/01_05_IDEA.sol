// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IdeaSimulated
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    B5YPBY7PBGP5!7B#BY5B#GYYGBG55YYY5GGPYJY5P5J~J55J~5#BGP5Y5BJJGPG5!GGPPP55YYJYY5Y5PPGGP!5BGP?YGYY55PBG?!5P?~5PYJJ??Y55YY55Y?JYYY5GGPY?J5G5~?5PGG?7PPYJPB    //
//    &#BP5PY7PP5GG7?#BJPBGYYPPPYJJYPP55YJ?JJJJJJ?~?5Y?!J5YY5Y5Y?BBBG!Y##G5YYJJ???JJJJY5G##J7BBBGJYYYY5YY7!Y5J~J5YJYYJ??JYYJJYYJ?7YYJYPPP?YBP!JBPPP?755YPB##    //
//    &##&#G5Y7?GBGP?7B#PYYPP5Y?JYYYYJJJ??YYYJJJ5P5~?GPY!7Y555PJPGGGJ7GG5YJ?JJJJJJJJJJJYY5GG75GGG5?5YY5Y!75P5~?YJ5P5PYYJJJ??J?Y55?7Y5YJJ5G#P7JPGB57?55G###BB    //
//    &&#####G5??5B##J!P#BP555Y7555PP5PPP55YYPPGGGGY!?PG5775GG5YBB#G!JP5YJJYYYJJJJYJYYYYYY5PJ7BBGPJ5GGY!JGPY~7JYP55P5555PGP5JYYYYY7JJJPGBBY!5BGPJ7JPG######B    //
//    &&&###BB#B5?P#&#P7?5PPPPY75PPP5PPP55PBGPPPPPGGG7?5JJ?!55Y5PGB5755JJJJJJJJ???JJJJJJJJJYY75BGPJYPY!?JJY!?GPPP5PPPBBGPPPP5PPPPPY?Y55P577PBBBJ75BBBBB####B    //
//    &&&&#BB####GYYB&&BY7J5Y5P5JY5P5555GGPGBP5GGGPYY?!7JJP57PPYBGY?J5YYJJYJ?7!!~~~!!7JJJYJJ5?7YGGYGY755?J~~?JJ5PPPPPPP5GGP5YYPPYPGP55YJ7YGBB5?JGBBBBGBB###B    //
//    &&&#B#&&#####GYYB&#GJ?YGBGYYJJY5GPPG5PP5P55J7!7J7~7PPPY?JPG55JYYYYYY?!!!777!!77!7?YJJJY??Y5GPJ?555J!~??!!?YYY55PG5GGPGPYJYYY5GGY?JG#BPJJPBBBB#BBBGBBBB    //
//    &&B#&&&&&&&&#&#PY5B&#P??Y5PPPYJJPGPPGPYYYJ?!7JJ7!!!J5PPP?YP55JYJJJYJ77?JJ??7???7!7?JJ?Y??5YGYJGP55?!!~7J7!7JJ?Y55PG5P5JY5PPP5J?JPB#GYJPBBBBBB#BBBBBB##    //
//    #B#&&&&&&&&###&&#G55GBGY7J5Y5PG5YPGPP5YJ7!~7J7!7J5J!J5PPGJY55JYJ?JJ??7J?7!!~!7?7777?J?J?J5YJJGPP5?75PJ7!??~!77?JYPG5JJYP5Y55J?5BBGYYPB#BBBB####BB#BBBB    //
//    B#&&&&&&&&#########GYYPBPJ5G5Y5PP5YY5Y??7~7?!!?55YY?!?P55PJJ??JYJ??77777?7!!7?7777?J??Y????JP55P7!J5Y5Y7!!?!~7J?Y5YJ5P5YYPGYYGBPYYPBBBBBBBBB########BB    //
//    &&&&&&&&&###########BG55GGJ5G5JYPPYJJJ?7!!?!~7YY555P5!!Y555JJ?7YJ???77!7?????77777J??YY77?JY5PY!!5P555J?!!!?!7????JYP5JY5PYYGG55GGBBBBBB###BB########B    //
//    &&&&&&&###&&&&##BB#BBBBG5PPJYP55YYYY?7?7!7!!7JJJJJJJJYJ~755JJ?77J?777!!!!!!!!!777777JJ!7?JJ55?!7J?J?YJ??J?!!?!???YYYJ?PJYYYPPPGBBBBGGBB#####BBB#######    //
//    &&&&&&&##&&####B#B####BGBPP5?5PP5J??7?7~?7!7JJJ?77?JJJYY!~JYJ7!7!7?!!~!!!~77~!!~!!7?7~!!7JJJ~!Y5P5J?77?JJY?!7?!?7?JJ?Y5YYJGPGGGB###BGBB######BBB######    //
//    &&&&&##&&&&###B#BGB###BGBBGPJJYJJYJJYJ7JJ!?YYY????JJJYYPP?^!7!!!!~!~^^^^::5Y::^^~~!!~!!!!7!~?PGPYJJ?????JY5J~??!?JJYJYYJJPGGGGBGB#BBBB###############B    //
//    &&&######&##BB#####BGBBBBBGPGYJY55YJY??57!5YJ?77?7?JJJ55PGY!~~~^^^^~^:...:JJ....:^!~^^~!~~!YG5YJ?JJJ?777??Y57!5J?JY5PPYJ5GGGPGBBGGB#####BB######B####B    //
//    &&#########BBBBB####B#BBGBGGGP55Y55YJ?J5!?G5J?7JJ7?JJ?JYY57?J7~~~^^:.:~!77!!7!!~::^^^~!~7J?7YJYJ?YJ?7JJ7?JYGY!5J7YY5P5YYYYPGBBBBGGBB#BBBBBB######B###B    //
//    &&####&&&#######BGBBBBGBGBBBBGGP5YY5Y?YY?!P5YJ?7??JYY55YJ?J7??~::^!7JYYYYYJYYJYYYJ7!^^:^??7J?Y555YYJ?77?JYY57?YJ7YYJJY5P5YJPGGBGGBBGBB###BBB##########    //
//    &#####&&&###B####BBBBPPPGPYYY555J?!?YYY?J7!J555YY5PYJYPJ!?5?~^^^!Y5YJ?7!!!~!7!77?JY5J!^^~~75?!J5YJY5YYYYY5J!7Y?YYY?!??JJJJJY5PPPGGBBB###BBB####&&&####    //
//    &####&&&#####BBBBBBBPJJ?7!~~~~~!!?J?JYJY55Y!7JPP55P5YYJ7?7J!~^~?5J??7!~~!!777!~~~7??Y5?^^~7Y777JYY5P555PJ!7YP5JJYYJY?!~^^^~~~!?JYPPGGGBBB#####&&&&&###    //
//    &##&&&&########BBBGPYJ7~^^^^^~^^^^~7?JY5PYY5Y7!?Y55PPP5PYY?~!~75J77!!77??7777??7!!777J5!~!~JYYPYGGPPPY?!?5P5YYYJJJ7~^^^^^~^^^^~!?Y5PGBB#######&&&&&###    //
//    ##&&&&&###BBB#B#BGGY?7~~^!77~!77^^~~JY5Y5JYYYP5?7?J555PPYJ~^~~YY77!!?7?7!!~~!!??77!7??5Y~~~~Y5PPY5YJ?7JPG5Y555YYJ?~~^^!7!~7?7^~~7?YPGBBBBBBB###&&&&&&#    //
//    #&&&&&&###&&#BB#GPP5J7!~~?J?!!?J7^~~7JPPYYY5PPGG5J7?JJ5P5Y!!^~Y?77!77??77!:^!7!7777777JY~~~!5PP5Y??JJYGGG5PPJYPY?!~~^!??!!?JJ7~~7?YPBB#BB######&&&&&&&    //
//    #&&&&&#######B#BBGG5YJ7!~!?J???7~~~~7JY555J?J5GBGPPJJ???JJ~^^~J77?777J??7777777??77??7JJ~^^~YJ??5PPGGYGB5J?J55Y?7!~~~~7?????7~~!JYPGGB##B#######&&&&&&    //
//    &&&&&&######BB#BGBGG5J?7!~~~~~~~~~!?JJJ7?YPPY??YPBBP5JJ5P57~!~7?77?7!7JJ?J???????77?7?J!~!~?55PY5P5G#GY??Y55J?7????!!!~~~~~~~~!?J5PGBGGBBB######&&&&&&    //
//    &&&&&&##########BBGGG5YY?7777!!!777???JJJ5PPPBPJ?YYYPP5?YP57~~~!??77!!!7?77?7?777??7JJ!~~~?PPYJ5GGPJJJYPGPPP5J?JJJJ??J777777??J5PGGGBGBBB##&#####&&&&&    //
//    &&&&&###BBBBB##B#BBBGGPP5YYYJ?J???7777?YYJ55GGG#BPJJYPG5YYP5?!~^~7??777!7~!!77?777??7~~~!J5PYY5GG5JYPB#GGP5YJJJ????JYYYYY5PPGPGGBBBBBBBB#BBBB####&&&&&    //
//    &&&&&#########B##B##BBBGGGPYJJYJ??J7?77YPP5YYYY5GB#BPPPY5YYYYY7~~^~!7?77777777??77!~~~!?YY5555Y5PGBBBG5YYYY5P57!77?JY55PPPGGGGGBBBBBB#BB#GB######&&&&&    //
//    &&&&&#######BBBBBGBBBBBBBGGP5555YYJ??JJ?JY5GGPP5YJYPP55P55YJJJYJ!~!~~^~~!7777!~^^~~!!7JYJJJYYYP5PPPYYY5PGGP5YJ?77!!?JY5PGGGGGBBBBBBBGBBB#BB######&&&&&    //
//    &&&&&######BB#BBBBBBBBGGGGGGP5Y??7777JYY55YY5PGBBGPP5PPPGGPYJ??J??!~~!~?J7~~7?7~!!!7JYJ??J5PGGPPPPPPGBBGP55YPPY5?7777??Y5GGGBBBBBBBBB#BB##B#BBB##&&&&&    //
//    &&&&&#####&###BBBGBBGGGGGGGPYJ?????J?7Y5GGGPP5GPPP5PPPGPPGBBBGGPPPPJ!~!JYYYYYYJ!!75GPPGGBBBBGGPGGGP5P5GGPPPGBPYJ??J?JJJ?JJPGBGGBBBBBB##B##&&#&###&&&&&    //
//    &&&####BB######BBBBBGGGBBGPYYYYYJYYYYJJ?YBBGPGGGGPPPGGGP555GB#####BBPJ!!?JJYY?!!YGB######BGP55PPBGGPPPGGGPPBGJJJYYYYYYYYYYJ5BBBBBB#########BB#B##&&&&&    //
//    ################BGBBBBBBB5YYY5YY55YYJYY??PGGGGBBBBBBGGPP5YJY5GBB####BGY!!!~!!7!YB#####BBGPYYY55PPGGBBBBBGGGG5?JYJYYY555Y5YYY5B######B#####&&&&###&&&&&    //
//    ################BB#B#BBBB5YY55Y5YJ7??JJ?JJYPGBBBBBBBBG55G5BPP5PBBB###BPJ!~^^^7JPB###BBGP5PPG5G55BBBBBBBBBGP5JYJJ7??JJYPY55Y55B######&&#&&#&&&&#&&&&&&&    //
//    &#######BBBB#######B####B55555YPYJ????Y5P5JYY5GGGGBBGPJ?JJJJ??J5PP5GBG5J~^^~^!?5GGP5P5YJ7?JJJ?7YPGBBGGGG5YYYPP5J??JJJYPY5P555B#&&&#B##&&&######&&&&&&&    //
//    #&&&&&##############B#BBB55555Y55JJJ?J5PGBG5J?YPGP5GGGP5JJJJYYYJ?7?Y5YJ?~^^^:~?JYYJ77?JYYJJJJYY5PGGPPGPY?J5BGGPJ?JJJY5555P55P#######B##&#&&&&#&&&&&&&&    //
//    #&&&&&&#####BBB#########BG55555Y55YY?J55PGPP5YJJYY55PPPPP5YJ?7!!!7??JY5?~:^^:~?YJ??!77!7?JJY55P555555YJJ55PGGP5Y?5555P5P5555B###&####&##B#######&&&&&&    //
//    #&&&&&&###BBB####B##BB####B5555555557JJJPGG555555YYYJJ???77!!!!!!777JY5?~::^^~?5YJ?7!!!!!!!7777?JYYYY5P5555GG5J?J55555PP5PPB&&&&#B####&#&&&#B&&&&&&&&#    //
//    ##&&&&&###B####BB#BB#BB####BGP5P5555?JYJ5PPP55GPPG5YYYY?777!777?7??JY55?!^^^^7?YYY?7?777!!!77?JYYYYPPPPG5PPPP5J??5PP5P5PPB###########&#&&&&&#&&&&&&&&#    //
//    ###&&#####BBBBGGGB##BBB###BBBBGPPPPPY?P5YJY5GPPGGGP5YYJJJJJJJ?JJJYYJYPYJ7~~~~?JYYYYYYJ???JJ?JJYJJYPPGGG5PP5YYY5YJ5PPPGBB###########&&#####&###&&&&&&&&    //
//    &########BBBGBB#BBB#BBBBBBB###BBBGGGP?5YJY5YYBP5GGGPP55JJ55YYYJJYYY5PPY?!~~~~7JYP5YYYYJJJYYY5YY5PPGGGGPPGYY5YJ5YYPGGB#####&&&&B#&#&&##&&&#B&&&&&&&&&&&    //
//    &###########BB##BBGBBBBBB#BBBBBBBBBBBY5G5Y55YPPPPPGPPPPPP5YYJYYJY5555YY?~~!~~!?5Y5P55YYYJJJJ5PPPPPPGGGGPPY55Y5GJPGBBGGBB#####&&#####B&&&&###&&&&&&&&&&    //
//    #############BBGGBBBBBBBBBGBBBBBBBGBBP?GBBBG5GPPGGPGP55PP55YY5YYPPJ7?JYJ7!^^!7?YJ??Y5PJY5YY55PPPPGGGGGPPG5GBGGPJGGBGBB####&&#B#&&&#&&&###&&&&&&&&&&&&@    //
//    &############BBBBBBBGBBBBGBBGGGGBBBBGPYJBBBBP5BGGPPPGGPPPP5YYYYPG5JJ5GGY?!!7?JYPPYJJPGPYYY55PPPPGGPPGGGB5PBBBPJ5PGGGBBB#&#B#####&B#&&&&##&&&@@&&&#&&&&    //
//    &&&###########BBBBBGGBBBBBBBBBBBBBGPPGGJYBBBG5GGGBGGPPGPPPPP55555PB####BGP5PGB####BGP55P5PPPPPPGGGGGBGGB5GBBBYYGGPBBBBBBB#####&##&###&#&&&&@@@&&#&&&&&    //
//    &&&&###########BBGBBBBBBGBBBBBBGBBPPBBBYJYPGBPPGPGBGGGGGGGP5PPPP555G#############GPP55PPPPPGGGGBBGBBPPB5GBGP5YYBBGP##B######&&BB&&&&##&&&&&@&&&#&&&&&&    //
//    &&&&###############B##BGGGBBBBBBBPPGBGYYBGPPP55PGBGGGBBGGGGGPPPPYJJYPGBB#####BBGPY?JJ55PPPGGGGBBBGGBGPPYPPPPGB5YGBPP#BB####&#B#&###&&&&&@@@&&#&&&##&&&    //
//    &&&&&###############BGBBBBGGBGGGGPBBGY5BBBBBBGPPPGBBGGGGGGGGGGPY5Y?JYPPGBB##BBP5Y?7?Y5YPGGGGGGGGBGBBPGPPG#BBBBBPYGBPG#BBGBBBB#&&&##&&&&&&&&#&&&&&&&&&&    //
//    ##&&&&&&&&&&&&&#######BBGPYJ??7?JYPPYPBBBBB#BBBPBGPGBBBGGGGGGGG5JJ??JYYJY5PP5YJ?J??JJJ5PPPGGGGGBBBGPGGPBBB######GYPBPYJ???JYPGBBB#&&&&&&&&#&&&&@@@@@&#    //
//    #B#&&&&&&&&&&&&&&####BBG5J7!7777!!??5BBBBBBB###GPBBBGGBBGGGGGPPP55PPGBBGPP55PPGGGPP555PPPGGGGGBBGGBBBPB#######B##BYJ?!????7!7YPBB#&&&&&##&&&@@@@@@@&##    //
//    &&###&&&&&&&&&&&&&&##BBPJ7!YY?!YY77?5GGBBGB#####GPGB#BGGBBBGBB####BBGGGBB####BGGGGGGB###BGGBBBGGBBBGPG#B###B#&#B##5?7Y5?!Y5?!?YGB#&&&&&&&&@@@@@@@&##&@    //
//    &&&&###&&&&&&&&&&&&&#BGPY?!?JJJJJ7?JPB##BB##BB##BGPGBBBBBBGGGGGGBGPP5YJ?J?YY????JY5PGGGPGGGGBBBBGGPPBB#BB&&BB&&&BB5?7?YYJJJ?7J5GB#&&&&&&&@@@@@@&##&&@&    //
//    &&&&&&###&&&&&&&&&&&&BBG5J777!!!!?Y5PBBB####B##BBBGPGBBBGBBBBGBGGB#BBBGPP5YY55PGGBB#BGGGGBGBGBBBBPPBB#####&&&###BG55J7!!7!7?JYPBB#&&&&&@@@@@@&##&&@&&&    //
//    &&&&&&&&###&&&&&&&&&&&#GGG5YYJ??YPGPPPGGGB#######BBBGGBBBGGGBBBBGGGGB###&&BG&&##BGGGPPGBBBGGGBBGGB#BB#&#&&&#BGGPPGGBG5JJY55PGGG#&&&&@@@@@@&&##&&&&&&&&    //
//    &&&&&&&&&&####&&&&&&&&&#####BGPY5B##BBGB#GPBGP########BBBB#BGBBBBBBBBB####PP####BBBGGBBBGGBBGGGB##BBB#&BGBGG##BBB####P5GB##B###&&&&@@@@@&##&&&&&&&&&&&    //
//    &&&&&&&&&&&&&####&&&&&&&&&&&&&&#55##&&##B#&&&&&######&#BGGGBBGBBBBBB#BBGBB55BBBBBBBBBBBBGBBGGGB#&#BBBB#&&&&###&&&&&#PG&&&&&&&&&&&&@@@&###&@@@@@@&&&&&&    //
//    &&&&&&&&&&&&&&&&####&&&&&&&&&&&&&G5B&&&&&&&&&&&######&&##BGGBBBBBBBBBBBBPP55PGBBBBBBBGBBBBGGBB##&#####&&&&&@@&&&&&B5B&&&&&&@@@@@@@&&#&&@@@@@@@@@@@&@@&    //
//    &&&@@@&&&&&&&&&&&&#####&&&&&&&&&&&#5G&&&&&&&&&&&&###&&###&#BBBBBGG##BBGGPGPPGGGGBBBBGGBBBB##&#######&#&&&&&&&&&@&GP#&&&&@@@@@@&&##&&@@@@@@@@@@@@@@@@@@    //
//    &&@@@@&&&&&&&&&&&&&&&&####&&&&&&&&&&P5#&&&&&&&&&&##&&BB##&&&&#BBBBGBBGGPPP55P5PPGBBPBBBB#&&&&##B#&##&&&&&&&&&&&#PG&@@@@@@@&&&##&&@@@@@@@@@@@@@@@@@@@@@    //
//    &&@@@@@@@&&&&&&&&&&&&&&&&&####&&&&&&&#PG&&&&&&&&&###B####&&&&&&##BGGGGBGGY775GPPPGGG###&&&&&&#B#B#&##&&&&&&&@&GP#@@@@@&&&#&&&@@@@@@@@@@@@@@@@@&&@@@@@@    //
//    @@@@@@@@@&&&&&&&&&&&&&&&&&&&&&####&&&&&BPB&@&&&###BB#&B##&&&&&&&&#BBGGB5GPY5PP5GGGGB&&&&&&&&##B##BB###&#&&&&[email protected]@&&&###&&@@@@@@@@@@@@@@@@@@@&&&&&@@@@@    //
//    @@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&####&&GPG#&###GB&&#B##&&&&&&&&&#BGPPP55JJY5G5PGG#&&&&&&&&&#BB&&#BB###&#G5G&&###&&&@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@@@    //
//    @@@@@@@@@@&&&&&&@@@@@@@&&&&&&&&&&&&&&&&&&#BP5PB&BB&##BBB&&&&&&&&&&#BBGP5555Y555PGBB#&&&&&&&&&#BG#&&#G&#GP5P#&&&&@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@#GPPGGP555B###G###&&&#&&&&&#&#BBGPPPPPPGB#&&&&&&&##&&&###G#&#G555PPPPPG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&@    //
//    @@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@&GY5Y?77J5GG55PGB&&#&&###&&&#&&&&&#BBGPB##&&&&&#&&&#B#&##&&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@&#GGPPJ7?????JPGBGPB##B##&&####&&&&&&&&&GG&&&&&&&&&##B#&&&#B##GGBBGY?????7!J5YPB&@@@@@&&&&&&@@@@@@@@@@@@@@@@@&&&&&&&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@&#BPPGBB5JBGP5GGYJG#BG&&B###&&&##&&&&&&&&&&GG&&&&&&&&&&B#&&&##B#&GB&#PJPGP5GGP?PGPPPGB&&@@@&&&&&@@@@@@@@@@@@@@@@@@&&@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGPPPPGG##G5GGGPGGP5B#&GB&##&&###B&&&&&&&&&&&[email protected]&&&&&&&&&#B###&&###P#&#B5GGGPGBP5B#G5PP5Y5GB&&@@&&&@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@#BGP5PPGP5PB#BB#BPY77?5G##&##GB#GB#&#G#&&&&&&&&#&&GG&&&&&&&&&&&BG#&#GB#PB&&&#BPJ77Y5PB#GGGP55PGPYYPGB#@@@@@@@@@@@&&&&&@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@&#GPPGPYB#BP5PGBBBBG##BPPGB#&##&&#P#GG###GB&&&&&&&#P#&GG&#G&&&&&&&&BG###PBBP##&####BPPGB#BPBBBGPYJ5B#GJ5P55GB&@@@@@&&&&&&&@@@@@@@@    //
//    @@@@@@@@@@@@@@&&#BBP55PGBBBPP5P#&BGGBGG#&&##B######&##G#&&&#B#B#&&&&&&&&&&&&&&&&&&&&&&#B#B#&&&#BB#&&###BBB#&&#BPGBGPG#GJ55Y5GGP5YY5G###&&&@@@@@@@@@@@@    //
//    @@@@@@@&&#BGGGPGP55PPGGGGPGBP5PGGBBGPPPGGGB#&&&&#####G&&&#BB&&&B&&&&&&&&&&&&&&&&&&&&&#G&&&BB#&&&B####&&&&BGGGGBP55PGGPG5J5P555PPGP555PPPPPPGB#&@@@@@@@    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IDEA is ERC721Creator {
    constructor() ERC721Creator("IdeaSimulated", "IDEA") {}
}