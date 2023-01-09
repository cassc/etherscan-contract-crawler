// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dafneth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    777777777777777777!!!!!!!!!~!!~~~!7?5PPPGP5YJJ?!^~!~~^^^~~^^^^^^^^:::^^:^::^^~^^^~~~~~~~~~~^^^^^^^^^    //
//    !!!!!!!!!!!!!!!!!!!!!!!!~~?5GY.:?5PPPPPPPGGP555GGBBBP5YY!^^^^^^^^^^^^^^^^:^~~:^:::^^^~^^^^^::.:::.::    //
//    !!!!!!!!!!!!!!~~~~~~~~~~^YBBBGGGGPPPPPPPP5Y5GB##BBGBG5??P5::^^^^^^^^^^^^^^^::::^^^^^^^^^::::::::..::    //
//    ~~~~~~~~~~~~~~~~~~~~~~^~PBGPJ7JGBBBBBGPYY5G###BBGPPPPGP?^J5::^^~^^^^^^^^^^:::::^^^^::::::^::::::....    //
//    ~~~~~~~~~~~~~~^^^^^^^^:7BG5G5??YPPYPBP5Y5B##BBBBGGPPPPPY7:??:^~~^^^^^^^^^^::::::::::::::::^::::::.::    //
//    ^^^^^^^^^^^^^^^^^~:...:YGPPB5JYY5YJYG55Y##BBBBBGGGGPPP5Y?!~!:^^^^^^^^^^^^^^:::::::::::::::::::::::::    //
//    ^^^^^^^^^^^^^^~JPGJ?YYPGGGGGYJ55P55PGPYG#BBBBBBGGGGGGP5Y?!!J?:^^^^^^^^^^^^::::::::::::::::::::::::::    //
//    ^^^^^^:::^^^::JGGGGGGGGGGGGGGGGGGGB#GP5BGGBBBBBBBBBGGGPY?!?PJ:::^^^^^^^^^:::::::::::::::::::::::::::    //
//    :::::::::::::^5GPGPPPPGGGPPGBGGGPGB#PYGPG5B#BBBBBBBBBBGP??PB^:::::::::::::::::::::::::::::::::::::::    //
//    :::::::::::::^PPPGPPPPGGPPPPPGPY5555PPBBPPPGB######B#B#PYG#?::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::5G5PPPPGGGPP55555PYYYYYYY5GGPP5PGGB######P7!~:::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::5GPGGGPP55YYYYYYYY5PP5YYJJJY5PPP5555PP5?!:..:::::::::::::::::::::::::::::::::::::::::.    //
//    ::::::::::::::PBGP5YYYJJJJJJJJ?JJYYJY5PPP5YY555YYJJJ!!~:.::::::::::::::::::::::::::::::::::.:::::.:^    //
//    ::::::::::::.~P5YJJYGBBGPY???JJ??JYY???J5GGGGGGP5Y7~?YJ!!....:::::::::::::::::::::::::....:::...:~77    //
//    ::::::::::::^5YYYYYGBBBBBBGY??JJ?JJYJ?JJJ??JJJJJJ~.^YYJJ?~?..:.:::::::::::::::::.......:~77?7~^~7??7    //
//    ::::::::::::JPYYYY55PPPPGPPPGJ?JJJJYYJ?JYYYJJJJ7: ~!JYJYJYY??!........................^7????????????    //
//    ...:::::::.?G5YYYYJJJY5555PPY??JJJJYYJJJJJY555!.:^?JYYJJJYJYY!^^^...................^!??????????????    //
//    ..........^PP5555JJJJ???J5YJ??JJJYY55YJJJJY555J~~Y?JYJJJJJYJ?J!5!..................^????????????????    //
//    ..........JP555YJJJJJJJYYJ?JJJJJJ5555JJYJJYJYJYYYY5YJJJJJJJJY55~7J..............:~!77777????????????    //
//    ^^^^^^::.:555Y5YJJJJ?JJYYJJJJJJY5555YJJJJJYYJJJ?7?JJY5JJJJJY5Y7!~^......:::^^~~!77777777777?????????    //
//    !!!!!!!!~JP55YYY55YYYJYYYYJJJY5PP5P5JJJJJYYYJ???~!!?P55YYY555Y??7~:^~~~!!!!!!!!!!7777777777777777777    //
//    !!!!!!!!!JP5YYYYJJJJJJJJYY5Y5GGPPP5YY55YYJJYYJJJ!!7YGP5555YYYY5Y?7~.!!!!!!!!!!!!!!!!!!777!7777777777    //
//    !!!!!!!!!J55YYYJJJJJJJJJY5PGGGPPPPPPPPGGPJ?7!!7J?JJYGGPPP5YYYYYYY?!^:!!!!!!!!!!!!!!!!!!77!!7!!77!777    //
//    7777!!!!7PPP555YYYJJJYY55PGGGGGGGGGP55PPPPP5Y!^:~J5~!5GGPP555YYYYYJ?.:77777777!7!777777777777777777!    //
//    77777777!5P555YYYYYYY55PGBBGGGGGPPPYYYYYY55PPPY?~^?7!7PGGPP555555YYJ~.!77777777!777777777777777!!777    //
//    7777???7JGGPP555YYYY55PGBBBBGGGPPP5YYJJYYY555YJ?!:.!777PGGP5555555YY7^!?7777777777777777777777777777    //
//    ?????777JGGP55YYYYYYY55GBBBBGPPPP5555YYYYYYY5YY55J:J?J!7GGPP5YY555YJ!::7777??777777???77777777777777    //
//    ??????77JGPP555555555PPGBBBBGPP5PP5P55YYYYYY5YY55?7J?57~JGPP55YY5YYJ7^ !????777???7777?????7??????77    //
//    ????????JGPPP55YYYYY555GBBBGGPP55PP5555YYYYY55YY?::7??7!!YGPP55YYY55Y?:.7?777777???????7????????????    //
//    ????77??75GP55YYJJJJYY5PBBBGGPPP55PGP5555YYY5YYYYJ!.^~77!!5GPP5Y55YYYY7:^??????77777????????????????    //
//    ???7777775PP55YYYYJJYYY5BBBGGGPPPPPPGPP5555YYYYYYY?^7P5J?!~JGPPP5P5P55Y?~?7777777?????????777777??77    //
//    7????7777YGPP55YYYYYYYYYPBBGGGGPPPPPGGPP5P5Y5YYYY557 ^7YPP5JGGGGBBGGGGG57JJJ?????????77777??????????    //
//    ????????7YGGPP5YYYJJYYYY5GBGGGGGGGPPGGGPPPYYYYYYYYJ::?^::?BGGGBB5YY55J!J7?777777777777777???????7777    //
//    ????77777YBGGPP55YYYYY5Y5GBBGGGGGGGPPGGPP55555YYYYY7.J57~^7GGBB5Y5YY5Y:.:!777777???????????777777777    //
//    ?????7777JGGGGP5555PPPGGGBBBBBBBBGGGPGGPPPP55YYYYYJJ!.PGPGPGGGG5Y5PYY5Y7^.~???7777??JJJJJ??????77777    //
//    ?JJJJJ??7JGPGGGGGGGP5555PBBBBBBBBBGGGGGGPPP555YYYJJY?~PBGGGGGGG5Y5#BYYY5777^??7777777777???JJJ???777    //
//    777777???YGPPGGGP55YYYYYY5##BBBBBBBGGGGGPPPPP555555YJY7?GGGGGGGPYPBBP5YPY!5?^Y5YJ?777!!7777777??????    //
//    777777777?GPPGGGP555555YYYP####BBBBBBGGGGGPPPPP55YY5GY?!7GGGGGGGPGGGP5YPP?~J~7BGGP55YJ7!7777777?????    //
//    7777777777JGPGGBGPPPPP5555Y5B#######BBBBBBGGGPPPPPGPPYY?^5GGGGGGGGGGG5YG5Y?7^YBBGGGG5YY?77??????????    //
//    ?777777777!?GBBBGPPPPPPPPPPYJG############BGGGGGGPP5555J~5BBBBBBBBBBBGGBG55J:7BBBGGGGP5J!!7?JJJJJ???    //
//    ????JJY55PGGB###BGGPPPPPP55G5YG############BGGGPPPP555PP?:JB##BBBBBGGGGGBP?~^ :JPBBGGGGPY?7!7?????77    //
//    GBBBBB######BBBBBGGGPPGPPPY5#BGB############BGPPPPPPPPPP?~..!YBBBGGGGGGGGGG5Y7^::75GGGGGGG5Y77?77777    //
//    BBBBBBBBBBBBBBBBBBGGG5PP5GG5G######BB########BGGPPPPPPPPGP?!!~75BBBGGGGGGGGGGGGPJ~!7GGGGGGGPJ!7????7    //
//    BBBBBBBBBBBBBBBBBBBGBG5GPPBGB#BBBBBBBBBBBB####BGGPPPPP555PGPY7:.^?GBGGGGGGGPPPPPP57.7BBGGGGGP5?!!7??    //
//    BBBBBBBB#B##BBBBBBBBB#BBBBB##BBBBBBBBBBBBBBBBB#BGGGGPPP55PPPPP5Y?^7BGGGGGGGPPPPPPPY7.YBBBGGGGP5J777!    //
//    BBBBBBBBBBBBB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#BBGGGGGPPPPPPP555J5BGGGGGGGGPPPPP5P5?:?BBGGGGGPPJ?YY    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGPPP5Y5GB#BGGPPPPPGGPPPPP555~.YBGGGGGPP57?Y    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract daf is ERC721Creator {
    constructor() ERC721Creator("dafneth", "daf") {}
}