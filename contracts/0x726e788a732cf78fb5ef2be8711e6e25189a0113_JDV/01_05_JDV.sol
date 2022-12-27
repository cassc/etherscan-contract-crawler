// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JPEG da Vinci Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ^^~!7!^^^!7!77???77?JY?777!~~J5Y?77?YG##P??J?????777??7!75~::::~##BG&GG&B~!7~~!!^^^~!7????J??7~!!?7!    //
//    ^^^:~!!!~!!!!!77?7!7!7???J?~!!7?YYJ?JJY&#5JJJJ5?77??J?7!^5G?~~^[email protected]@J##BBJ:!!!!!!!!7??JJJJ?7!!~~~~7YJ    //
//    77!^^[email protected]@[email protected]&GP77!~!!!!777?777??7~~~!J?77?Y    //
//    7???7!~^^J55PJ?7777!!^^!!77~!7!!777JYJ77YG&[email protected]@#5JJ???!~~!~~!~~!77!!777?YYY?7    //
//    ?YY5PY7!~!7?JJJ!~~~!!~~!~!7!^~!77?YYJ??!!7GB7!7~!777JYYYYYJJYY5G55#[email protected]?J??7!!~~!!?J!!??7!??~~JP?    //
//    YYGGYJ?7!!77YBGYY?!77!7!?J?!~J?!7!~~7?YJ7^7#G~!?!~!7?JYJJ?JJJYYY5G#G&&5Y7?7?JJ???7777????77???7!~!?G    //
//    PB##GPPY!???~Y&#[email protected]!J!~~!~!?Y???7?????J##&5Y57!!?7??7JJJ???7!~^^~~^^^~7!Y    //
//    5B&&&#&GJPPP5PGGGY~J57~7J?JY755J??JYPYJ??JY5#&5J!~!~~~~7??JJ?77?J5&BBYPG?77??7!~!777???7!!!!~~^^^~!!    //
//    ?P&&&B&[email protected]#5Y~~^!77!~7??77J55G&GPBBY?J5Y?7?7??7!!???7!~7?!~7!~!~    //
//    ##@&&&@PJJ5Y7G&##PY??J?77?????JYJJJJPGPYBG5?J5&#BY7!!77JP55J??YY5B&G#&J?Y5J!?JJYJJJ77!!!7!!!!~^^^~!!    //
//    BB#&B#&&#BYPB&BBGYJJ?7???J??7??5Y?5Y5PPG##GYJ5P&P5YYYJJYP5PY????P#&BP7?PPJ7!7JY?JJJ?????!!!^~^~:.^^~    //
//    777?JBPJY#BB&&G5JY5YJY??Y5YY7!7??JJYYJ??5G#&&BPBBG5GP5YJY5YJJ5PG#@#J!YPY??77JJ?7JJJJJJJ?77!~77~~~~~7    //
//    !YY7?PGPP#&##BP5GPPJ???YPP5Y??PJJJ??????5PPB&@@&&@BP#GG5YG#&@@&#@@PYGJ~~!!~!7??5GYJ????77777???????J    //
//    !!!!!7YBGJ777?YPP5J77?5BG5YY7~5J7?JYYYY?7??77?YP&#&#BG5J?Y5GP5GG&###7~!77?!7??Y5YJJ????7?7?77???J?7?    //
//    !!!!777!~~~~~~^!?JJ7?JY55?7!!7JY??7JJJ!!7????J55Y55Y?!!!!!~^^!JBBY7!!!7JJ?!777JJY??77!!!!7?~~~7??7!!    //
//    J???J77!!!7J555J?!7????J?JJJ7?5YJ5???7?JYP##G5J57YY7?JYYYY5PP5?????JJY5Y7JYY5PPPB5J55JJJYJ7?JJJJ????    //
//    GGGY5Y!7J5G##GPPGGY?55G&JPYYBBPGGP5JJYYBBPG5YPGGPY?5555PPGGGGPP?J5GGPPGPJ5PGBBBGGGY###BBG#YPGG55J5GG    //
//    #BGP5JYG#@&[email protected]@@@&BGP5G5PP&&&BG#G55Y#BBB&#BPPGPYJ55###BGB5GB#BB#BBB5B#&#BBBPP##GG5B&&    //
//    &&@&BY5&@@&#G5#Y5Y7J55YGGG#G5Y5B&&B5JJYY?#&&&##B5PPG&@@&@@#GBP5Y#&&@@&#PP###B&&&&GP&&@@&BB#B#@&#5GGG    //
//    @&@@GJP&@@&&BP&#[email protected]#[email protected]@&#BBBG55&&&&&@@@#[email protected]&&@@&GB&&&B&&@#PPGGB&[email protected]@@@&P?7?7    //
//    @@@#[email protected]@@@@@####&&P&#?JY5P##BJY5P&@&&@G&&&#5YJJG5Y#@&&#&@&GY?J5G&@@@&BYYPBBG##&G?5&BGG57?J?J??JY55P    //
//    &@#?75&@@@&&&@@@&##[email protected]&&&JJJYG&@&G7!~~^^^^[email protected]@@&BY7~^~^!YY5BB55PGGPY!!~~~^^~!J5?777777!!5G##    //
//    [email protected]!~~^^~!7?Y5JJ#&&@&BG#5YYYPBB!^!!~!77?7??!^[email protected]?7!~~~~!~~~^~7GBPY?::^^!777!~^^^^75PYY55JJY55    //
//    JYBY7~!!~~^[email protected]@@@BGG5GP55P?7JJ?JYY5GG5YYJJYGPPPJ??JYYYJJ77!~~7!!7?777YYJ7!~^~~!Y5PB#BY77~:    //
//    PY5^~?JY5PPPYYJY????!!5&@@@BP5JP555?!?JJYYYPGB&&#YP5?75GGP5GP##BBGYYY?!P&#GJ!~^::^:.::::.:^!7JPB?~!?    //
//    BJ77JY5GB##BP5Y5YYJJ?!7##GPJ77!~^^::^::^^~^~~!7?J7YJ7!75PG#@@@@@@@&BB57YJ~^::::^::..^!!~~::^^^~!7JYY    //
//    #5?Y55PPGGGP5YY5YYJ?77~7~^::^[email protected]@&@@@@@@@@@@&Y~^!~^~!!~~^~!~77~7~~~!~!~^!J5    //
//    #P?J5PPGGGGPPPPPPGGPYJ!!7?????JJJ???J5J?JJ??J???J???7?!7Y#@@@@@@@@@@&J777?YPPGP5Y?7YY5?7!!77~777!!~7    //
//    BBJYY5GB#&@@@@&&&@@@&YJ?7?YJ?YJJJ????JJJJJJYYYYYY5YYJJ?777Y#@@@@@@@#Y7?JJPG#GGBPYY?JYY????~77~7~7!~^    //
//    5J55Y5PB#BB#&@#[email protected]@@@@&G?JYY5G#G5PGYYYY55Y5###G5555J???!    //
//    &Y?Y55PGGGP5G#PJ?JJ~!?77Y5Y55Y??JJYY??7J5GGGGGBBBB#[email protected]@&&&YJYJ?PGPPP55555PGGBBGP5J?7?PBP??7    //
//    Y?77PPB#&&&##&&BBP!J57J5JP55YY55YY5J7JYY5GB#######BGGPPP55J7?J#@&&#J5G5YYP5P555GGB##BP555YJY??!?&Y~P    //
//    5YJJ?YB&@@@@&&@@&5!7~~J5?JY5PPPGPPPGB#BP5PPGBBBBBG55YYYYYYPGBG5&@@BJP5P55GG5PPPPPPPP5PY55GPGGGPY5J~?    //
//    G55J7PB&@@@@&###[email protected]@GJGYG5B&&P555P5555P5555J???!!!J?!^    //
//    GGB5JPB&@@@@@@#YJJ!!7YG&#555PPPG###BGBGGG5555YJJYJJYJJ5#[email protected]@BJPPGGP&&P5PPGGGGBGGGGP5P555YY5J?!    //
//    #BPPGGP#&&&##GJYJJGBBB#&BY55PGB#&&&#B###&&&&&&##PJJYYJ5#[email protected]@&JP#GB&&@GPGGGGBB#######BB#&##GGBY    //
//    GBGGP##&@&###?5PP#@@@@&&@5YPPPG##@@@@@&&#BPPGB#@@#[email protected]&G7YGBGB##BGPGGB##&@@@@@@@@@@&&@@&#    //
//    JY?7Y#&&@@&##PP##&&&@@@@@&P555GB####&##BGBP5PBB&@&GB5?JYPGGGPYJ&&#77J5GGB#&@#BBB#&&&@@&@@&&@@@#BBBPY    //
//    YJ?!7B&&@@@@@@B##G#&#&&@&B5JY5PB#BGPBB##&@@&##B#&&#GGYJJ5GGP55GBP7!7?YP##&@@&&&&&&&&&&&&##BGB#&&#BGY    //
//    [email protected]&@@&&@&PYP5PBGBG#&PJY5PGGGBGGPP55PGP5PG#&#&&&#G5Y?GBGPBY^~!7?JJYB#&@@@@@@&@@@@@@&&&&&#B#BB#G5    //
//    PP55PB&&@@&G?!^^!Y5BGGB#&B55PPGGGB#BB####BGP##&&&@&&&#B5JB&Y?7^^!!!??JYB&&@&&&&&&&@@@@@@@@@@@@@@@@&&    //
//    YY55GB#@B57^~!7!~!?JGB#&&&&G5PGPG#######GGG5G&#&&&@&##BG5#&?^~7?JJYJYPB&&&&###&&&&@@@@@@@@@@@@&###G5    //
//    ??JJYPP?^:^!7???7YPG#BB&##@#5PB####&&&##BBGGG##&&&&&&&#B##Y!?J5PGPGGB#&&@&B###&&&&&&@@@@@@@&##B5??!~    //
//    7!!777~777???JJ?JGPPB#B##&&&P5B#BB###&&&&##BBB&@@@@@@#PYGP??G###&&&@@@@@@&BBB###&&###BGGB##BG5J7!~~~    //
//    ??7!!~7????7?PBPGBGG##BB&@&&&GPGBBBGPBB####&&&&&&@&#[email protected]@@@@@@@@@@@&###&##B##PJ?7!!7JYYYY?7~~!    //
//    YJ77~~7!777JY55YPPP#BGG#@&@&&&BGGPPP5GGBGPGPGB&&&@&##[email protected]@@@@@@@@@@@@&B##B###BYJJ??7!!7??5GP5JY    //
//    ??J5Y?!7JJ?YP5Y55GBB##&&&&@@&&&&#BBBGPBBBGBGGBB##&&[email protected]@@@@@@@@@@@&##B####&B5PGBPY???7J5BBPY7    //
//    JY5GGJ?555GBBGGG#&&B&@@&@&&&&&&&@&&&&#&&&&&&&&&##BBBGY7:!5BGYG&@@@@@@@@@@@&##&##&&G5G##B###P5YPGBYY7    //
//    GBB##J?YGPG##&@@&##&&&&&#&&##&&&&&&@&&@@@&#&@@@@@&GP5J!^[email protected]@@@@@@@@@&&##&&#&&@GP#&&&&&#GGJ5GPYJ5    //
//    B##&&P?JB#&&B#@&##&&#&#BB##B#&&&#&#&#&@&&&##&&&&#GGPJJ?!!J?7!7JB&&&&&BGGP555PPPGBGPB#@@@@@&PGYP&BPPB    //
//    &#BGGPJ5B#BP#&&&&###BBBBBB#######&########&#B##BBBGBBG5?77!!!~^^JPBBBPP5Y??JJJJYYYJYB&@@@@&PJ7J&@@PG    //
//    GG##[email protected]&&&&##&###BBGBBGBB#&B########BGGGGBG#G5GBJ?J?7JJ7^:^^[email protected]@@PP    //
//    &&&@GJJ?JPBB#&##&##&#&##&&&BBPGB####B#BBBGGGBGGGGGYYYJJJ??7~~7?~^^^:7GG#BGGPYYYYJYJJJYJ5GB###B#@@@&&    //
//    PP5GG?^!?PGGGGG#B##&&&&&@@&BBGGBGGGGBBBGGGBBGBPBG?5PJ?7?J5Y!!!77~~~^:?&#&###BB#P5GGGBBGBB###PG&&@@&@    //
//    !?YJ555?7Y5PGPGB#B###&&&@@&&&#B#BBBGGGPPGB&&&BPJ5JY?7??J5Y?7YJ?77~~^::[email protected]@@@@&&&#&#B&&@&&#&#GB&@@@@&@    //
//    YJ?7?Y!^!J5GGGBBBBBB#&&@@@@@@&&#&&#BB#BBB#&#BPPJ5Y555JJJ?7JYJJ!7?!^!!:[email protected]@@@@@#@@@@@@@@@@#&@#[email protected]@@@@#&    //
//    !!?!7?!!!JP#&@&&#BBB##&&@&&@@@@@@@@&&&&&&&@@[email protected]@@@@@@@@@@@@@@@@@@@@#B#@&&B#    //
//    7!!~!!~:^?YG&&#BPGBB#B#&@&@@@@@@@@@&@@&&@@@@#[email protected]@@@@@@@@@@@@@@@@@@@&#BGGB#BGB    //
//    !~!!7~::~75GGGBBBBBBB##&&&@@@@@@@@@@@@@@@@@&B#BG#G5G#GGGB5J!7!Y5?Y?YP&@@@@@@@@@@@@@@@@@@&#GP5PPG#BG5    //
//    ~!!~^^~^^JPBB#B#&&@####&##@@@@@@@@@@@@@@@@@@@BG#[email protected]@&@@@@@@@@@@@@@@&&#BG#BBBBG#BP5    //
//    [email protected]@@@@&#&#B#####&@&&@@&&###&&&#B&#BPG#BG&&#GY5GGP55GBYY5BGBBBGB&@@@@@@@@&&&BGBB#&&@&&&#G5    //
//    !!7^~7?!77:^[email protected]@&&&B##B####BBBGB#&#BPBGB&BGGBB#&#BBBBGG&&#@#PPPPP55?YYGJ5JY#@@##@@@&&&&&BBB&@@&BBPBGP    //
//    Y7!:^!7!!?!!7G&&&&#B#BBBBBGBBPGGGGGGBG5G5P55BGPBBPGBGB&B5G#GG5PBGG5YY!!~?5P#&[email protected]@@@@&&&&&@&#BB5?JY    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JDV is ERC1155Creator {
    constructor() ERC1155Creator("JPEG da Vinci Editions", "JDV") {}
}