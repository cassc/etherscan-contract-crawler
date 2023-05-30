// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Mystery
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ~^^^^^^^^^^^^^^^^^^^^^^^::::::::::::::^^^^^~~^::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^^^^^::::::::!J55555PPPPPGPYJ7~^::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^^::::~?JYYY5BBGGGGBGGGGGG555YJ?7~^:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^::^^^^^^^PGPPGGGBGGGGBBGGGGBGGY555Y?7!!~^^::::........:::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ^^^^^^^^^^^^^^!7J?J55555PGG55BBBGGGGGGGGGPGPY7JY55Y??777?????77!!~~^^::::....:::::::..::::::::::::::::::::::::::::::::::    //
//    ^^^^^^^^^^^^~Y5JP5PGGBP5PBBGGBBBGGGGGGGGPPPY??YY5YYJJJJ?????JYJJJYJ????7!!~^::::::.:^^:::..:::::::::::::::::::::::::::::    //
//    ^^^^^^^^^^^:YBY?PG5PBGY5PBBGGGBGGGGGGGGGGG5??J555YYYYYYYYJJJ????????JY???JJ?7!~^^:!5GPY?7~^^:.::::::::::::::::::::::::::    //
//    ^^^^^^^^^^^^?G5YGGYB#PGGGBGPGP5PGGGBGGGBG5Y?J5555YYYY5555YYYJJJ????????77?Y?7???7!!7Y5PPGP7!!^::::::::::::::::::::::::::    //
//    ^^^^^^^^^^^^~GGP555GPGBGG5P555PGGGP555GGG5J?Y55555555YYJJYYYYJJJ???J???????77??YJJ7!~~~7YGGJ7!^:::::::::::::::::::::::::    //
//    ^^^^^^^^^^^^^~?PBGBP5P5GBPGGPPGGGPPPPPGPYYJJ555555Y55YYYJJYYJJJJJ??J???????777777??J?7!~~?GPY7!~.:::::::::::::::::::::::    //
//    ^^^^^^^^^^^^^^:^7JYGBP5PPPBBGBBBBB#BGGPY???Y555555YYYYY5YJ5YYYJJJJJJ??????J??7777777??JJ?!7YGP??^:::::::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^:::~7?5PYJ5G##BBBGGGPGG5J7J55555555YYYYYYYYYYYJJJJJJ????????7777777!!!!7JJ77PGY?!^::::::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^::^PGPYYY55GPPPGBPPGP55Y555555555YYYYYYYYYYJJJJJJ?????7?77777777777!!!77!?PPY7!~^::::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^^:!B##P#B5JP5J?JPGP5Y5PPPPP55PP55555YYYYYYYYYJJJJ??????J????77777777!!!!!!5GY?7!!!~::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^^:!GB#GGPGPPP5YJJ55YJ??YP55PGGPPPPP55YYYYJJYYJJ?J?????7?7??JJJJ?77777!!!!!Y5Y?!!!!!::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^^:^Y#G5GBGPPPP55YYYY5YJ7Y5Y?YGGGPPPP55YYYJJ????????777777?JJYYYYYY??77!!7!?J?7!!!!~::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^:~P&#55PPGPGBG5YYYYYY55JJY5Y??5PGGGPP55YJJJJ?7!7?7777??JJJJYYYY55P55YJJ77!??77!!!!!~:::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^:!G##GYP#BG5YYP5Y5PPP555J??Y5Y7?Y5GGGGPP5YJ????!!7!7??JYYY555PPPPGBBGPP5J!!J?7!!~!!!^:::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^:!P#G5YYBBB5JJ5GGPG#BGG5PG555YJ!!7J5BBBGGPY?77777!!7?JYY55PPPGGGGGGB##BGP57!?7!!7~!?~.:::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^J5YYYY5BG5JJ5GPPPG#BGP555GPPP5JJJJYBB#BGPY7777777!?JYY5555PGGGGGBBB###BG5J!777!!~!PY7^::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^~YYYYYY5BPJJYPGP5PGGP555J??J5GGP5YYYGBB#GPJ7!!!!777?JY5555555PGGBBB####BBPJ777!!!!~J5Y7^:::::::::::::::    //
//    ^^^^^^^^^^^^^^^^:!YYYY55PBPJJJ5P55PG5GBBPJ5PGYPBPGPPGBBBGP5?7!~~!!!7?J55PP5P5Y5PGGB#####BB5J7!?7!!!~!??7^:::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^JYYYYY5BBPYJJYPPPBBB#GPPY?JJJY5Y5B###GP555Y?7!~~~!7?J5PPP55555PGGBBB###BGY?7!7Y7!!!!?!^::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^~YYYYYYPBGPYJJYB#&#BGP555Y?77?JYYYG#GPPP5555YJJ?7~~!7?YPPP55555PGGGBB###BGJ?7!777!!!!~::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^:~YYYYYGBGPYJ?Y###GPPPPPPP5YJ?JYY5PPPG5J5BBPPPPP5J!~!7?JYYYYYY5PPGGBB###GP?77!77?7!!~:::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^?YYYY5BGGPYJ?YPBB###GPPPPY7JYYY5PGGP5JP##PGGGBBGPJ!~~!7?????JJY5PGGB##BPY?7!!??5?77!^::::::::::::::::::    //
//    ^^^^^^^^^^^^^^:~JYYYYYPBGGP55JJJ5GGBBPPP55YJY5PGGBBGJJYB#BP5PPG##BGJ!~!!!777??????JYPPPPY?77!!JP5Y77?!^:::::::::::::::::    //
//    ^^^^^^^^^^^^^~7YYYYYY5BBGGPPP55Y5555Y5Y555PPGGBBGGGJ?Y5BBBG55PGB#BBBJ~!!!!!!77777777?YYJ7?7!!!!?J??7JY!:::::::::::::::::    //
//    ^^^^^^^^^^^^!YYYYYY5PGBBGGGGGPPPPGGGGGGGGGGGBBGGGGY7?Y5PGGGBGGGB####57!!!777777777777???7?77!!!!!?7?G5J~::::::::::::::::    //
//    ^^^^^^^^^^^^?5Y55Y5BBBBBBBBGGPPPPGBBGPPPGGGGBBGGGPJ7??YYPPGBBBBB#&##P?!!!77777?J?77!77??77777!7!!7JJBY7!::::::::::::::::    //
//    ^^^^^^^^^^^^^7JY5YYPBBBGGGGGGPPPPGGGPPPGGGGGBBGGGPJ7???YPG5PPPB&&##BP?!~!!7777?YYJ?77?????777!!!!77?P?7~::::::::::::::::    //
//    ^^^^^^^^^^^^^:^J5YYY5GGGGGGGGGPPPPPPPPGGGGGGBBBGG5????JYPP5YYYPBBBBBPJ!!!!!777?JYYJ?????7777!!!!!!!?J?7!::::::::::::::::    //
//    ^^^^^^^^^^^^^^?YYYYYY5GBBGBGGPP55PPPGGGGGGGGBBBBBPJ7?YJPG5YJ??J555GGGY!!!!!7777?Y5YJJJJ??77!!!!77!7???7^::::::::::::::::    //
//    ^^^^^^^^^^^^^JYYYYYYYYP##BBGP555PPPGGGGGGGBGBBBBBGPYJ?J55YJ7!!!???J5Y?!!!!!7777?YY5PYJJJ?7777J?777??77~.::::::::::::::::    //
//    ^^^^^^^^^^^^^?YYYYYYY5#B##P5P55555PBBBBBGGGGBBBBGGPPPPPGGGGP?!!!777??77!!!!7777?JPG5JJ?7??7JJ777!7??77?:::::::::::::::::    //
//    ^^^^^^^^^^^^^755YYYYYP###B5Y5Y55PGGBBBBBBBBBGBBGPPPPPPBBGBBP?!!!777??77!!!!!777?Y#555Y?7777?J?7J5???777!::::::::::::::::    //
//    ^^^^^^^^^^^^~YYYYYYY5PPBB#G5555Y5B#BBBBBBBBBBGPP5PPPPPGBGBG5?7!77777?J?7!!!!77?JG&PP55?7!?????JYPPGP5YJ?!.::::::::::::::    //
//    ^^^^^^^^^^^^^!?YYYYYG#PP5PGB5JYY5G#BB###BBBBBGP555PP55PPPP5YY?!!7777???7!~!!77J5BGP5J77!7???YB&#GGBBB###BJ::::::::::::::    //
//    ^^^^^^^^^^^^^^^~JYYYYBGBPYGBB5JYGG5G####BBBBBBG55PPPP5PPPYJJJ?77!77777?7!!~!!75PP5YJY7!!7YYP#&&&&#BB##&#GJ::::::::::::::    //
//    ^^^^^^^^^^^^^^^:^JYYYPBBPYY5#GY5#5YPGPGBBBBBBBGPPGGPGPP555YYJ???77777777!!!!!JP5YYYJY?77?5B&&&&&&##B###BP7::::::::::::::    //
//    ^^^^^^^^^^^^^^^^:!YYYP#BYJJGG55GPPGYJ5GBBBBBBBGGGGGGPPPPY5JYYJJ?77777777!!!!!Y5YYYYJ5P7!!J5#&&&&&##BB##BBB?.::::::::::::    //
//    ^^^^^^^^^^^^^^^^^:~?Y5GBY5GBGPP5555YJYGGGBBBBBBGBGPPPGGPYYJY5YJ777??77!77!!!75YYYYYY5Y7!!7?5&&&&&#BG#&BG#G!.::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^:^~7JYPG#BBPGBGPP5Y55GGGBBBBBBBBPPPGGP55YY55Y?777?77!!7!!!?5YYY55YYJ!!!?7?B&#&##G##GG##P::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^^:::^~YPPGPBGGGP555PBBBBB###BGGGPPGGP5P555YYJ?7777!!!777?YY5YY55YYJ!!?57Y#####BB#B###Y^.:::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^^^::::^Y5P#G5PY5YYGBB#B#####GPP5YYYJJ?J?7777?777??J5GGP5P5YYY5YYYYJ7!??Y&#GG########J:.::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^^^:::::::^?PPP5P5PGGGB####&BY5YYJYYJ?77!~~~~~^~JBB###BBGG5YYYYYJY55777?B#GGBBBBB#BY!:::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^^^:::::::::~?5PGBBGBBBGBB#B555YYJJJJ?7?!~~^~~?P##BBGGGBGG55YJJYJJYJ?J?P#BB#BG?7GY^..:::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^^^::::::::::::^~YGGGPG5Y55Y55YYYJJ??777!!7J5GBGPP5YYYYP#GG5J?JJYGB##&&&####BBG!7:.:::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^^^:::::::::::::::~JYJYY?!!JPPP5YYYJYYYY55555YYYJJY555PG#BGJ77!^^^?PGPY?7777!!^:.:::::::::::::::::::::    //
//    ^^^^^^^^^^^^^^^^^^^^^::::::::::::::::::::::::::~7JYY5555555YYY5PGP5G#&&###BP?:........:..........:::::::::::::::::::::::    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MSTRY is ERC721Creator {
    constructor() ERC721Creator("The Mystery", "MSTRY") {}
}