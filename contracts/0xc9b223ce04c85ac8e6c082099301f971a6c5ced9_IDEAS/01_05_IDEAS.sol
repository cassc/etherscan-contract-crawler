// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IdeaEditions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    PPPPP555555555555555555YYYYYYYYYYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJ????????????????????????????????????????????????????????????JJJJJJJJJJJJJJYYYY    //
//    PPP55555555555555YYYYYYYYYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJ????????????????????????????????????????????????????????????????????????????JJJJJJJJJJYY    //
//    P5555555555555YYYYYYYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJ???????????????????????????????77777777777777777777777777777777777777777777?????????????JJJJJJJY    //
//    55555555555YYYYYYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJJ????????????????????7777?7777777777777777777777777777777777777777777777777777777777777??????????JJJJJJ    //
//    5555555555YYYYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJ????????????????7777!!7?JJJ?~??!J!!??77!!!!!!77777777777777777777777777777777!777777777777777?????????JJJJ    //
//    555555YYYJYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJ?????????????777!!!~~~~~^^^~!YBJ7B5J#5!PGJ!~^^:::::^^~~!!777777777777777777777!?J!~!777777777777777????????JJJ    //
//    5555555Y?7!7YYYYYYYYYYJJJJJJJJJJJJJJJ???????????77!!77?JYYJ?!~~^^^^^^~??&@[email protected]@P?57!~~^^:::^^~~~~^^^^~!!77!!!!!!!!!!!!!!7Y57!!!!!!!77777777777???????JJ    //
//    5555YPPYJ7!!!YYYYYYYJJJJJJJJJJJJJJ???????????7!!!?YPB##&&&&#J~~~~~~^^[email protected]@@[email protected]@@#J!!!!~~^:^YGGBBGGPY?!^:^~!!!!!!!!!!!!!!!!7!!!!!!!!!!!!777777777??????J    //
//    555YYPBP5J??7YYYYYJJJJJJJJJJJJ?J?????????77!~!?5B#&&&&&&&&#Y!~~~~~^~J#@@@@[email protected]@@@@BJ7!!!~~^?B########BGY!:.:~!!!!!!!!!!!!!!!!!!!!!!!!!!!!77777777??????    //
//    55YYYYPBBG5JYYYYJJJJJJJJJJJJJY7????????777!!JG#&&&&&&&&#[email protected]@@@@@[email protected]@@@@@&B5?!~!!~~?5B########BP?:.::^~!!!!!!!!!!!!!!!!!!!!!!!!!!77777777????    //
//    5YYYYYY5PPYYYYYJJJJJJJJJJJJJ?JJ??????7777!?G#&&&&&#BPY?7777!~~!?P#@@@@@@@@[email protected]@@@@@@@&BPJ7!!!!!!7J5GB######G7:..::^~!!!!!!!!!!!!!!!!!!!!!!!!!7777777???    //
//    YYYYYYYYYYYYYYJJJJJJJJJJJJ???????????7?7!YGBBGP5YJ?7?JJ?7!!!?YB&@@@@@@@@@@[email protected]@@@@@@@@@@#G5J7!!?J?7!!7?Y5PGGGY^::..:^~!!!!!!!!!!!!!!!!!!!!!!!!!777777??    //
//    YYYYYYYYYYYYJJJJJJJJJJJJJ?????????J?777!JJJ????JJY5P5J7!77JP#@@@@@@@@@@@&G5?5&@@@@@@@@@@@&BPY?!!?55YJ?77!!!!!!^.::::::~~!~~~~~~~~~!!!!!!!!!!!!!777777?    //
//    YYYYYYYYYYJJJJJJJJJJJJJ???????????777?!Y555PPPGGB#P?!!7?5B&@@@@@@@@@&@@@#[email protected]@@&&@@@@@@@@@#G5J~^?GBGP55YJJ???:.......:~~~~~~~~~~~~~!!!!!!!!!!!777777    //
//    YYYYYYYYYJJJJJJJJJJJJ?????????????JY5?Y#####&&@@G?~!?JP#@@@@@@@@@&@@@&&@#P5??B&&&&@@&@@@@@@@@@&BPJ~:[email protected]&##BBGGG?:!^:.....:~~~~~~~~~~~~~~!!!!!!!!!!7777    //
//    YYYYYYYJJJJJJJJJJJJJ??????????J5GB#&#?&@@@@@@@B?~!?YG&@@@&&&@@@@@&#@@&&&[email protected]&&@@##&@&@@&&&@@@&BP?::J#@&&&&&&#~GGPY7~:...^~~~~~~~~~~~~~~!!!!!!!!!777    //
//    YYYYYYJJJJJJJJJJJJ???????JJ?YP#&&&@@[email protected]@@@@@#Y~^7YB&@@@@&&&&&@@&&####&&##BGPPGB#&##B#&&@@&&&&&@@@@&#P!.^5&&&&&&@?J&&##B57:..:~~~~~~~~~~~~~~~!!!!!!!777    //
//    YYYYJJJJJJJJJJJJJ???????JJJ5B&&&&&&&[email protected]&&&@G7~~?PPP&@@@&&&@@@&&#PP#BBBB##G5J5BGBBBB#GP#&&@&&&&&&&@#55GJ:.7B&&&&&P^B#####BP7...^~~~~~~~~~~~~~~!!!!!!!77    //
//    YYYJJJJJJJJJJJJJ??????JJJ?5#&&&&&&@#JG&&&&[email protected]&&&@@&&&#GJ!YB?5GBBP5Y7?5BBGP?GG!?P##&&@&&#&&P~~!JJ:.^P&##&B^J#######BJ:..:~~~~~~~!7?77!~~!!!!!!7    //
//    YYJJJJJJJJJJJJ???????JJ?7JB&&&&&&&&[email protected]&&Y!!~J?77!J&&#&@&&&&&G!!J#&?!?P5Y5Y???J5?!!B&5!~5&#&&&&&###J~~~77:.:Y&#&G!!G######BB?...:~~~~~~YP5JJ7!~!!!!!!!    //
//    YJJJJJJJJJJJJ??????JJJJ?!5####&&&&[email protected]&Y!!~77777Y&&##&@@@@&&PYB&&&P?5P5P5J7?Y?JJJ5&&@#55&#&@@@@&#&&5!~~!~...J&&J?J!B####BBBP:...:^~~~~JPPYYY?!~!!!!!!    //
//    JJJJJJJJJJJJ??????JYJJJ?!Y##&&&&BYJG&5GY77~~7!!?G&#PG#BPG#&#&&&&&#&&GPPP55Y?J??J7J#&#&&&&&#&BP5P#B5B&BJ!~!^...JP~B5!~5######J....::^~~~~7YPPJ7~~~!!!!!    //
//    JJJJJJJJJJ???????JJPYYJJ?7JPPP5J7JP#@#J77!~!7JP#B5?!Y#5?5B###&&&&&&GGPP5555JJJ?7??YB&#&&&###B5?Y#5~!JPBGJ!~....:[email protected]^!JYYY!...::!::^~~~^~J?~~~~~~!!!!    //
//    JJJJJJJJJ????????JJBB55YYJJ????J5P#&@B?77!~5GGP5YYY75##BY?7??G##GJYGGGG5PP5JYJ???Y??JP##GJ77?YG##5!5P55PBB5~....Y&&BPJ7~^::::::^!5!.:~~~~~~~~~~~~~~!!!    //
//    JJJJJJJJ????????YJYB##BBGGPPPPGB#&&&&Y?77~?G5YYYYJJY##P!!!!~JBGG5JGGGGGPPP5JYYJJ?J?JJ5GGBJ~~~~!5##YP5PPPPPBJ....:G####G5Y??7???7!?J..^~~~~~~~~~~~~~!!!    //
//    JJJJJJJ???????7JYJYGGGGB###&&&#&@@#&G??77^J5YYYYYYJ?P#J~!!!7BBJP&#GGGBPJJYY!7777JYJJG&5?##?!!~~J#B55PPPPPPPY:....!BG&@&BBBBGY?!^^!Y:::^^~~~~~~~~~~~~!!    //
//    JJJJJJ?????????YYYYG#BGPPGB##&##&&B#Y???7^JYYJYJYJJJ?YY7!!??PB#&B5PBP55Y?5?!J!??7?JJ?G#BBBJJ!~7PP5555PPPPPP5^....:5PB&GGBGJ!^^~7J5Y:^::^^^~~~~~~~~~~~!    //
//    [email protected]@&&BPPPGB####BBJ???7^JY???JYYY?J?JJJJYYJJY55!7JYGBB??!!!7YP57?!!?JJJJY5Y5PP55Y5P55555P5^...:.7PPGGGJ~^^!YG##&?^~^^^^^^^~~~~~~~~~!    //
//    JJJJ?????????7YGY5BJB&&&&&BPPPG#&##5JJ??7^???7?JJ555YJJJYYY5JJYJP?PGYJ5??J5J!~!?7JP?7?~7~!55PPP555PPGPY5Y55Y:.:::::YPGP7~^~JG#BB#G:7!:~^^^^^^~~~~~~~~~    //
//    JJJ?????????775P5Y#5J#&#&&&#GPPG#&PYJJ???~7??777?YPPP5YY5PPP5P#P5JYJ777?YY55YJ?!!~777!JJ?7JPPP555GGGP5YYY55J:::::::^55!~^7PBBGGBB~:Y^~~^^^^^^^~~~~~~~~    //
//    JJJ????????77?Y5BJG#YYB#&@@@@BPGBG5YJJJ??!~????77J5GGGPGPJY5PP5JJY5JYPGPP555555P5J??!~!???!?7YPPGBGGPYY5555!::::::::^!~^J#&&&BBG!.J?:J!^^^^^^^^~~~~~~~    //
//    JJ?????????77?5B55Y#[email protected]@@@@@BGG5PYYJJJJ?^?JJJ?7?5555PGBYPB#5JG5?5GPYJJ????7!~~!J5Y7?7^?557~JYY5PGG5Y55PP5^:::::::^:^^Y&##&&&5^:JJ^!!?~^^^^^^^^~~~~~~    //
//    J?????????777JPYBBY5##5J5#@@@&GGPPG5YYYJJJ!!YJJJJ?JYY55P#PBB#5YJJG5J???777777!^:..~J57~^!Y5Y?YJYY555555PPP7::::::::^^^^?B#&#G?:~YJ~^?J!~^^^^^^^^~~~~~~    //
//    J?????????777J5BPPBP5B#B5Y5PPPG#PPGP5YYYYJJ~?YJYYYJJY5PGBBGG5YJJG5Y555YYJ?7777!~^:.^Y5!~^77?YYYYYY55PPPGGJ^:::::::^~:~J~~77~:^?Y?~7Y?7?!^^^^^^^^^~~~~~    //
//    ?????????7777JB55B#&GYB&#PYY5P#&5PGG555YYYYJ~?YYY5555PPPPPBP5PJ5GG#&&&&##G5J7777!~^^7P7!7~?J77?Y55PPPGGGY~^^::::::~~:!#J^:::!5PJ~!55YJ~?~^^^^^^^~~~~~~    //
//    ?????????7777J5GG5GP5B#PYPB#BGGBPPGBP5555YYYJ!J55PPGGGBBBGGPPGYJBBB##BBBBGGPYJJ??77!JP77?~7JJ5PPPPGGGGGY~^^^^^^^^^!^^~7~?YY?~^!YY!~J?7J!^^^^^^^^^~~~~~    //
//    ????????77777?P5G#J5#GJ5#@@@@@BGGPGGBPPP5555YY7YPPGBBBB##BBBGYY?PBGGGGGGGGGGGPP55YJYPY!~~JYYPPPGGGGGGG?^^^^^^^^^^!~^^!~5&&&&#5~:?57:JY~!^^^^^^^^~~~~~~    //
//    ???????777777?YBP55#GJP&@@@@@@BGBPPGBBPPPP55555?JGB#BGGB#G##&PYJ75GGGP55555PPPP555PPJ!!~JGBPJP5PPBBBP!~~~~^^^^^~7!^^!J!J##&&&@B?:75!~!?~^^^^^^^^^~~~~~    //
//    ???????777777755BYBGJG&&&&@@&GGB#BPPGB#GPPPPPP55YJPBBGGBB5PGBPYPY7?5PP555Y55Y555P5J77Y?~JYY?75PPPBBJ~~~~~~~~~~!?!~^~55?!JB###BB#J:?5^?!^^^^^^^^^^~~~~~    //
//    ??????7777777!JG55#YP&&&##&#PGB#&##GGGB#BGGGPPPPP555GBBBBGB###GPPYY???YY5Y555YYJ?!?YJJJPGGP5Y5PGGY7!!!!!!!!!!?J!~^!55BY?7?PBGGBB#?^5!^!^^^^^^^^^^~~~~~    //
//    ??????777777777P55PY#&&&&&BGB##@##&&#GGB##BGGGGGPPPP5PGB#&BB#&&GGPG5J??777?7777!7755JJYBG5Y5#BPY7!777777777JJ?!~~JBBPB&PYJJPBBBB#B~77^~^^^^^^^^^^~~~~~    //
//    ??????77777777!J55Y5&&&&&#BBBGGGPPGB##BBBB##BBGGGGGGGGPPGB#GGGGB#PBGPGPYY5P5?7JPP5PYJBYYYJY55J7????????JYYY?!~~7JYJ??7JJJJY5GBBB##7~!^^^^^^^^^^^^~~~~~    //
//    ??????77777777!!Y5YP&&&&B5YJJJJJJYY55PGBBBBBB###BBBGGGGGGGGGB#&&#P5B##&BYGYY5?GBB#5?JGGBPYJ??JJJYYYY5555J7!~~~~^:::......:^~?P####?^~^^^^^^^^^^^^~~~~~    //
//    ?????777777777!!75Y5&&B5JJJJJJYYY5PPGGGBBBBBBBB########BBBGGGGGB#BBB#BGPYBBGGYYY5P5YY5YJ??JY55PGGGGP5J?!!!!!77777!!~^^::::::::7G##7^^^^^^^^^^^^^~~~~~~    //
//    ?????777777777!!!?55#GJJYYYYY5GB#&&&&&&&&&&&###BBB####&&&&##BBGGGBBGP5PGBYPY?PG5??JYJ??JYPGB###BP5J?77?JYPGBBBBBBBBBBG5?~^::^^:^PG~^^^^^^^^^^^^^~~~~~~    //
//    ?????777777777!!!!?5PYYYYYY5B&@@@@@@&&&@@@@@@&&&#BB######&&&&&#BGPPBBPBGGB7!YJJGYYJ??YPB##BBG5YYJYYYYPB##&&&&@&#B#&&&&&&#5!^^^^^7J^^^^^^^^^^^^^~~~~~~~    //
//    ?????777777777!!!!!J55555Y5#@@@@@@@@@@&@&&&&@@&&&&###########&&&&#G5PGGGPGJ7YJY5577JG#BGP5YYY55P55PB#&B#&&##BG#&#&&&&&&&&#P!^~~~!!^^^^^^^^^^^^^~~~~~~~    //
//    ??????777777777!!!!!?5555Y5&@&&&@@@@@@&#&@@@@@@@&&@&&&#&&####BB#&&&GY5PGGB?!55Y5!!JBG5YJJ5YY5555G#&&@P#&&&&&&#5G&&&&&&&#&#B?~~~!!^^^^^^^^^^^^~~~~~~~~!    //
//    ???????77777777!!!!!!?5P5YYB&@&&&@@@@&B&@&@@@@@@#&@@&&BBBB#&&&#BBB&&5YYGBP~^5PP?!!P5J7JGBBBGYJ?YG#&@@5B&&&&&#&&JB&&&####&#P!~!!~^^^^^^^^^^^^~~~~~~~~!!    //
//    ???????777777777!!!!!!75PPYYG&@@@@@@@[email protected]@@&&&&&###BGPGB#&&####&&GGB#5Y5B5!~^~YBJ!!J?!5BPYY5PB&#PJ7?YGBPG##BB#&@5Y&&##&&&#57~!!~^^^^^^^^^^^^~~~~~~~~~!!    //
//    ????????777?J7777!!!!!!!JPP555PB#&@@@[email protected]@@@&#GPP555G#&@@@@@&#BB##PGBPPPJ~!77~^7Y??7!?PJ?JP#&@@@@@BY7!7?J5PB#&&@PJ&&&#BGY7~!!!^^^^^^^^^^^^^~~~~~~~~~~!!    //
//    [email protected]@&&&&&&@@&BB#PPBB57!Y#&&#Y~~?YJ~7J7Y#&BGGGB#&@@G?!!!~!!7??J?!J??7!~~!!!~^^^^^^^^^^^^~~~~~~~~~~~~!!    //
//    J???????J55YJYJ?7777!!!!!!!?5GGGPPPPPPY55YYYYYYYY#@&#&&&&&&#&&&#BP5#[email protected]@@@@@5~!55!!?YBGYJYYY5PGB&@B77!!!!!!!!!!!!!!!777!^^^^^^^^^^~~^~~~~~~~~~~~~!!!    //
//    [email protected]@####BB##&##&&&GY#[email protected]@@@@@[email protected]@5777777777777777?7!^^^^^^^^^^~!?!~~~~~~~~~~~~~!!!    //
//    [email protected]@#B#BB#######@@&YG&[email protected]@@@&J~!PY~5#@[email protected]@577777777??????7!^^^^^^^^^!~^!Y5YJ7~~~~~~~~~~~~!!    //
//    JJJJJ?????YG#PJ??77777777777!!!!!7YPBBBBGPPPPP55Y&@@#BB######B&@@@BYB#J7!?YY?!^~55~J#&@[email protected]@#????????JJJJJ7!^^^^^^^^^~7?!~^~J5?~~~~~~~~~~~~~!!    //
//    YJJJJJJJJJ?JYJ?????JJ????????7777777J5GBBBGPPPPP55#@@&##B####&@@@@&#YP#5?7!~~~75Y7J5&@@@#PP5555G#@@BJ?JJJJJYYYYJ7~^^^^^^^^^^~JY??J7~^~^~!?!~~!~~~~~!!!    //
//    YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJJJJJJJY5GBBBBGGGGP5P#@@@@@@@@@@@@@##&[email protected]@@@@@&&&&@@@B5JJYYYY5555J7!~~~~~~~~~!!!!7YJYY7~~~~!?JJ7?JJ!~~~!!!    //
//    55555555555555555555555555PPPPPGGGGGBBBBBBBBBBBBBBBGPGB#&@@@@@@@@BB##@BYGBJ7JP?J#PPYP&@@@@@@@&BP5YY555PPP5P5555555YYJJJJ???????JJ77!!!!!7YYJ?J7!~~~!!!    //
//    PPPPPPPPPPPPPPPPPPPGGGBBBB#######BBBBGGGPPPPPPGGBBB#BBGGGGBBBBBBGB#&##@#5G5?PJ5#PP#G55PGGGGP5555PPGGGPP5YJJJJJJYYY555PPP555YYYJ??7!!!!!!!!!!!~~~~~~!!!    //
//    PPPPPPPPPPPPPPPPGBB#########BBGGGGGGGGGGGGGGGGBBBBB#######BBBBBBB##&@#B&&PPYYG#PG&&BBGGPPPPGGBBBBBBGGP555YYJJJ?????????JYY55P555YYYJ?7~~~~~~~~~~~~!!!!    //
//    55555555YYYYY5GBBBBBB#BBBGGGGGGGGGGBBBBBBBBB######&&&&&&&@@&&&&&&&@&&&&##&5YBBGB&&&&&&&&&&&&&&&&&###B#BBGP55YYJJJ???????????JY5PP55555Y7~~~~~~~~!!!!!!    //
//    YYYYYYJJJJJJ?PBBBBBBBGGGGGGGGBBBBBBBB#########&&&&&&&&@@@@@@@@@@@@@@@@@@&&G5B#@@@@@@@@@@@@&&&&&&###BBBBBBBG555YJJJJ?????????????J5P55555!~~~~~!!!!!!!!    //
//    JJJJJJJJJJJ??J5GBBBGGGGGGGGGGBBBBBBBBB##########&&&&&&&&&&&&&&@@@@@@@@@@@@#[email protected]@&&&&&&&#####BBGGBBBBGPPPPP55YYYYYJJJJJJJJJJJ??JJJJJJ5555Y7~~~~!!!!!!!!!!    //
//    JJJJJJJJJJ??????J5PGGGGGGGGGGBGGPGBBP5P##BBBBBBBB#############################BBGGGGGGBGGG5555PPP55Y5PPYYYYYJJ??????JJJYY5JJJJJJJJYJ7!~~~!!!!!!!!!!!!!    //
//    JJJJJJJJJJJJ????????JY5PGGPYG55PPYGGBBB#BBBBBBBBBBBGGGGGGGGGGGGBGGBGPPPGP5555PGG555PP5PPP5555555555555YYYYJJJJ?????????JJJJJJ??77!~~~~!!!!!!!!!!!!!!!!    //
//    JJJJJJJJJJ55YJ???????????JYY555GBGGPY55P#BBBBBBBBBBBBBBBBBBGGGGGPPPPPPPP55555555555P5PPPPPPPPPPPPPPPPPPPPPPPPPP5JJJ??????77!!~~~~~!!!!!!!!!!!!!!!!!!!!    //
//    JJJJJYYY5GP5JJJ?????????????????JY5555YJPPGGBBBBBBBBBBBBBBGGGGPPPPPPPGGGGGGGGGGGGPPPPPPPPGGGG5YYPGGGGGGGGPPP5YYJ77!!!!!~~~~!!!!!!!!!!!!!!!!!!!!!!!!!77    //
//    YJJJJJJJJJJJJJJJ????????????????????????77????JJJYYYYYY555YYYY5PPGGGGGGGGGGGGGGGGPPP55Y555YY55YJJJJJ???777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!777777    //
//    YYJJJJJJJJJJJJJJJJJ??????????????????????????77777777777777777777???????????????7777777!7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7777777777    //
//    YYYYJJJJJJJJJJJJJJJJJJJJJ??????????????????????????????77777777777777777777777777777777!7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!777777777777777    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IDEAS is ERC721Creator {
    constructor() ERC721Creator("IdeaEditions", "IDEAS") {}
}