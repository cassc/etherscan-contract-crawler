// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFA COMICS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    ~~~~~!!~~~~~~~~~~~~~~~~~~JGGBBGBBBBBGGGGGBGGGGGGGGGGGGPGGGGGGGGGGGGGGGGBGGGGGBGGBBBGGGGBGGBBGGBGGGBG    //
//    !?7!YBB#GBGGGGGBG!~~B#BPGBB5B#YBBBP&&5#YBGGPGJ#P&P~Y&#JBBP5BB5#J^[email protected]#[email protected]&BP#&P##P&5#GG7775PPP7~    //
//    757~5GBBBBGGGGGG?^^^#&@G&Y#YPPJ&J&G&&Y&P#?&G#PBY##:?&?5BJ##GPB#P~^&&&##J?&&&G#P##&P&&#&?Y&!^~~!5G?~^    //
//    !!7777??777!77!!~!7!J?Y?75J~??7PB55GGPGYG#PYBBYPGPJYP7?GB5YBBYGBPYP75JY5J5?5Y55JG#GGPPG55BYYYY5PG5YJ    //
//    ^~JPJ???77~~^^~?J??7?5P5Y?7?J5BBBBBBBBBBBBBBBBBBBBBBBBBGGGBBBBB#B!::...:~^:::.:^5PPB#BB##BBBB##BBBBB    //
//    5GBBBBBBBBBGGGB###BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBY~:..:!Y?77~:::::::::...::::::~~^~?GBBBBBBBBBBG    //
//    BBBBBBBBBBBBB###BBBBBBBBBBBBBBBB#BGPPGBBBBBBGP55GG5PY::..........^^~~~~^^^::::::.....:::~JPBBBGGGBBG    //
//    BBBBBBBBBBBBBBBBBBBB#&PYJ?77!G&BY?77??JBBBY7!!!!!J7?77PY......:!77????J#Y7????7?5Y~::::::::!7^::^~JG    //
//    BBBBBBBBBBBBBBBBBBB#@&!!!7JYY&P777????75P!!!7?7!!?P!7J#^..::.^[email protected]@7::::::::........^    //
//    GBBBBBBBBBBBBBBBBBB&@G~!7BBG&Y!77P#@5!77!!!5B#B!!?7!!#Y!!^^^?7!!?G#G777777?#&#B##5^::::::::^^::::::.    //
//    GBBBBBBBBBBBBBBBBB#@@J!!777??77?B#[email protected]!!!!7G#BBG!7J!!5&BBBBGG777Y&@BB?!77777JJJ&@J.:..:......:^:^:::.    //
//    GBBBGPGBBBBBBBBBBB#@&!!!PB&&777GBB##!7!!!5#BBB??B?77BGPB#B#[email protected]&BB5!J?7!5BBGG##~....:.......:..^^^:    //
//    GBY^:::^YBBBBBBBBB&@G!!?#[email protected]&!77JPB#?J&?!!7PB&GYBG?J?777#&B#[email protected]@5~^^^^^:.:^!~^^~!77?YPGGP    //
//    ~^:.....:[email protected]@J!7P#B&@B?7JJJ#&&@&YYG&&##&&#BPGBB#&#B#G?7!!!JG&@[email protected]&BBBGGGGPPPBBBBBBBBBBBBBBG    //
//    .............7BBB#@&GBB#BBB&@&#&&&&&@@@@@@@@@@@&&&&@@&#BBBBBBGBB#&&#BG#&&&BBBBBBBBBBBBBBBBBBBBBBBBBG    //
//    .....:::...:.:!JPBBBBBBBBBBB##&&&@@@@@@@@@@@@@@@@@@@@@@&BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG    //
//    :.......::...:..:JGBBBBBBBB##&&&@@@@@@@@@@&@@@@@@@@@@@@@@&BBBBBBGGP55BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG    //
//    :::::::.:::.:::::.:77?Y5PGB#&&&&@@@@@@@&[email protected]#@#@@@&@@@@@@@@&BG5Y?!~~~!7GBBBBBBBBBBBBBBBBBBBBBBBBBBBBG    //
//    YY5PPP5?7!7?YPGGPYY55P5YYP##&&&&@@@@@&&P?PP?PYB&&&&@&GP5Y5Y?7!??~~!?7!?BBBBBBBBBBBBBBBBBBBBBBGGBBBBG    //
//    B#BBBBBBGGGPGPGBB#BBBBBBBB###&&&&@@&B?J?5P5?!J~P&#&&&G?7??7??JJ7!YYJ?J7PBBBBBBBBBBBBBBBBBBG?^^^~?5YJ    //
//    BBBBBGY55PGPPPP55PG#BBBBBB###&&&&&&GYJJJ77777?!~P5?&&&&?!~!!7J7JGBBB55~YBBBBBBBBBBBBBBG5YY^.........    //
//    BBBPJ5PGG&&&&#BGGP5YBBBBBBB##&#G5P#PJ7!?!JBBBG!~~~7Y575Y7YYJYPGBBBBBBJ!YBBBBBBBBBBG5J?^.............    //
//    BBYYGPPPG&####GPPGG5JBBBBBBBBB#@#GG5??!!!7YY?7?!~!57!?7??B#BBBBBBBBBG7~Y##BBBGYJ??!~^:::::.........:    //
//    B5YG5JYJY55YY5Y5YY555JBBBBBBBB#@@&BGGPJ7!~77!!7?7Y5J7777?BBBBBBBBBBB7~!~J##BBBP~!77?~7~J?7J?J!!!!7YP    //
//    BJPGJYJYY5J?Y5J5?5JPG?BBBBBBBBGG5YYYPGBP5Y??????JYYJ?J?!5BBBBBBBBBBP!7YJ~5#BBJ^..7PYJ~YY?.:~5#BBBBBG    //
//    B5YG5PY5Y5YY55Y5Y5JP5JBBBBBPGP55P5?JJYJ7?J75YJJJ5Y555YJYBBBBBBBBBBBGYY?7?GBBBY~Y57YYPYP5Y~~^7PBBBBBG    //
//    BBJ5GGPB########GGGPJGBBB#G?55555JJ7!7JJ7YJJPJY5YJJ?~75BBBBBBBBBBBBBGGGGBBBB#B5Y7^~!~!!7?5J5BB#BBBBG    //
//    BBBY55P&&&#&&&&&PP55G#BBBBY?!?5Y7?5!~!7?7J5?YP7~!~~~^7#BBBBBBBBBBBBBBBBBBBBBBBB#BG5YY5?GYBBBBBBBBBBG    //
//    GBBBG555GPGGGGPGYPGBBBBBG77J?JJ5??57^~^!??5??YY^!7JJ~YBBBBBBBBBBBBB?~^!YBBBBBB###BB####BB#BBBBBBBBBG    //
//    BBBBBBBGGPGPPGPBBBBBBBBBYJ55YYYY7~~~:::~??YJJ?JJ7755JGBBBBBBBBBBBB5^::!^JB####BGPPGPPGBB###BBBBBBBBG    //
//    BBBBBBBBBBBBBBBBBBBBBBG?7J7J???J?!JY???5Y~!?JJ??77?!!BBBBBBBBBBBBBB7!!~:YPP5J7YJ!!?7!777J5PBBBBBBBBG    //
//    BBBBBBBBBBBBBBBBBBBBBG!!?!7??YY?YB##B5P5J!777?J7~~7^7#BBBBBBBBBBBBBP!~!!PJ!~~!JJJ7?7??7!~!7?GBBBBBBG    //
//    BBBBBBBBBBBBBBBBBBBBB7~!!?Y5Y5PGBBBBBB57!~!~~!~7!!?^7BGBBBBBBPGBBBBBB5PBJ!!~~!7YPYY5GBGGGP7!JG#B#BBG    //
//    BBBBBBBBBBBBBBBBBBBBG~~!7J5GBBBBBBBBBBB?^~7~?775!!Y~7GY5BBBBP!?YPBBBBBBJJJ7!77??????JYBBB#BJ77G#B#BG    //
//    GBBBBBBBBBBBBBBBBBBBG5GBBBBBBBBBBBBBBB#G7~?~~?~!!~!JGPYJPBBBPJ7~7BBBBBG7?JP5?JJJ?????7JBBBBBY~7###BG    //
//    GBBBBBBBBBBBBBBBBBBBBBB#&&&&&#BBBBBBBBGBGPJ7!~!??J5P5JJYYG#BBBBP7~JPGBY7?JBBGPJJJJJJ???P##BB#Y~P##BG    //
//    GBBBBBBBBBBBBBBBBBBBBB&@@@&GYG#BBBB#BGPPPPGPPPB#BPYJJJJJJ?PBBBBBBP?~~7!77PBBB#PJJJJJ???5####BJ~?BBBG    //
//    GBBBBBBBBBPY7!7J??5GPG&@@G77!YGBBBBBP555555555YYJJJJJJJ????GBBBBBBBG5YJJGBBBG5JJYJ???J?5##BG5!~~?BBB    //
//    GBBBBPY?JYY55PGP?!~~~~P&5Y~~?YGBBGB5555YYYYYYYY555JJJJJ????Y77?Y5PGBBBBBBBGY???J?????JJY##BB#PYJYPBB    //
//    BB##PJ77P#BBBBBBBBB?~!PB!!YG5?JYY55YYYYYYYYY5555YYYYJJ?????Y7!!!!!7?JPBBGY??????YY?JJJJJB####GBGBB#B    //
//    JJJJY?JJJJ55Y5GGPP#BG##?~7G#YJ5JYPY5YYYYYYYY5?5YYYYYJJJJ???Y5JYY?J?J7JPY7??????J55?????YGG5YYYYJJYYJ    //
//    777!~7!77YPGGB&&##&&&##PPBBJ!!7?5PYYJYYJJYY5Y7Y5YYYYYYJJJ??JPJJJJJJJ???7??JJJJ77Y??????Y55?7!!7777!7    //
//    YJY?!Y?!Y&&&&##&&&&#BBBBGYJJJ?7JJGYJJJJJJY55J?YPYYYYYYJJJ??JPYYY5YYJY57?YYJ7!J7?577777YY55YYJ?YJYJ?Y    //
//    ????7J?7?B###@@&&&&&&#57??JJJ??JJG5JJJJJY5?JYJ5PYYYYYJJJJJY5Y?JY5YYY5??JY????JJYJ????YY555YJJJJ?JJJJ    //
//    ??7777??JJ?Y&@&#&&&&&BJ7JJYYY??JYP5?JYYYGJ75P5PP5YYYYJJJJJYPYYYJ5555???JJ??JJYY5J???YYY7?YJJJJJ?YYYJ    //
//    ???JY5J????Y#B5G5YJG#J7!?J?!7!JYY5Y~^~7YYJ!YP5PG5555555YJJY5J?JJYY57777YYYJJ?YJYJ?JJYYJYYJJJJJJ7??JJ    //
//    ??7?YY?????JJJJ!^~?YJ777J??!7!?JYYYY???J?J7Y55GP5555555J???Y7!JJY5?77?J??J?JJJ?JYYY5YJJYYJJJJJY??7?J    //
//    7?7??7????JY5?~~77JJ?~!!???!7!?JY5Y5JJJJJY555YP5YYYYYYJJJ??5?J?J5J77JY!~~7?J??!???!77?YYYYYJJJY5Y7?J    //
//    JYY55YYYY?7777J5P5555YYY555555PPPPPPPPPGPP5J?7P555555YYYJJ?PPPPP5!77JP555YYYYYY5555YY55PP55PPPGP5Y5Y    //
//    PPGBBGPP!!J5PGGGGGPPGPGGPPPPPPPPPPPP5YJJ?!~^^~PPPP55YY5YYJJY!?JYP55YPPPPPPPGGGGPPPPPPGGGG5PPPP5PBBBP    //
//    PPPGB#&#5GGGBBBBBBBBBBBBGPPPPPPP5YJ?!!JYYYYYJ7J?77?77!!7?Y5?^^^~YPG5PGGGGGBGPPPPPPPPGGJYJY5PPJJJ5GBG    //
//    ###&@@@@@@&##GBGBPGGGBB###B55J?777~^~!5P~~~!J?J555J7~!7~~75~^~^!GG5?JP5PGGGGPPPPPPGGBJY!77JY55YYGGPG    //
//    #&&&&&&&&&&&B?YY?Y!P??J?5&BY?~^~??!~77?5Y77^JPGGGGGBP7~JYP55!~!5GYJYYJ777?JY5PPGGGGGPGGPY5YJJ?J5BGGP    //
//    PPPPPPPPGGG###[email protected]#????7?7!!~^~~~!7?JYY55PPPPGGGPPP5GGPPPP    //
//    PPPPGGGGGGGPGBGGBGBBBBGY?7!!~!7JJ?~!777!!777YBGGGGGGGGGG5P7!7777!!~^^^~~~!!!!!!!7?JJJY55GPPPPPGPPPPP    //
//    PPGGGGGGGGP5Y5YJ?775B?~~!7!!!!!!!~~!~?J!~!~~~?GBBGGGPPPPB5^~^^~~~~~^~~~~~~!!!!!!~~~!7?JJJJYY5PPPPPPP    //
//    PPGP5YY5PGPJ7!!!!!!!7!~~~!!7!~~~~~~~!7!^^^^~~!7JGBBGGGGB#7~~~~~~~~~^~~~~~~~~~!~~~~~~~~~!!7?JJ?JY5PPP    //
//    YJJJ5GBGPPGPY55G5555PJ?5PPGGG55PPPGGGBP?55PPGGGY5BG##BBG#YJJYYYYYJ?JJYYJYYYYYYPYJJYJJJJJJYP~!5G5Y5GY    //
//    [email protected]@#JJY&[email protected]@YJ?#&&#[email protected]#[email protected]&[email protected]!!!!777#J??JJJ??????5J?JB??777!7#G#PJ77!YB    //
//    ~~^[email protected]@JJJ##[email protected]?G&BGG#BGB#&GGG##&&&BGPGBBB#&?77&@?7?#Y77PBJ!7GG77YPJY???PBBYJ?BP77JGPG&&G?!??7?5P    //
//    ~~!&@[email protected]???Y#JJJBGPG&@&#&@#PGGBGB&[email protected]@[email protected]&@?77&@@[email protected]@&YJ5#?775PYB#?7J#&BGPJ~    //
//    [email protected]@J?J&&JJ??JY?75PPPPGPPGG&GGGBB##BPPGG~^[email protected]&?7?&&?7?&[email protected]@[email protected]@&777&@@Y??#P77??JY57777JJJJYG!    //
//    ^!&@[email protected]?J?J??J&&##&&#PPBBPPG####GP5#J7J&@5!7?Y?77PB7755777G&?77&@@[email protected]@B775&777GBB##P5PGGY77YG~    //
//    ^[email protected]@7~!&#?7Y#[email protected]&BBBGGG#&GPPPPPP#B55PGBPG&7!!77!!7&J77&&[email protected]@&777&@@J!!#[email protected]&PPG5??5P!~    //
//    [email protected]@#[email protected]??#@[email protected]@[email protected]@&[email protected]@#GPPG#@G?5#&GJ5B#[email protected]@B5&&JJJ#@@[email protected]@#JYP&JJJY55G#&J!77JYY?~~~    //
//    !55?7#@#5YJPPYJ?G#&#G5Y??GPJ?77!~~!YGBPY?JG5?7?BGYYBGJ?7!55?G#PJ?7Y#G5Y?J#BPYB#G5YJ?7?&@&BPYY?!~~~!~    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NFACOMICS is ERC1155Creator {
    constructor() ERC1155Creator("NFA COMICS", "NFACOMICS") {}
}