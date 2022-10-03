// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 30Inks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ......:^!!^:^?!~~7!7~~~::~^~~~~^^^^^::::::::::::::::::::::::::.....Y##B&&&&&&&&&&&&&&&&&&&&&&&&#&&&&    //
//    .....~7~!7^^^5?7?PY5Y5Y~.........:::::::::^~:::::7^::^Y^::::7^.....Y####&&&&&&######&&&###&&&&&#&&&#    //
//    ....~7?~:^!7~7!::~:~~?7!::::::...:::::::::?Y7:::~Y?::7Y!:::7P^.....J####&&&&&&&######&##&&#&&&&#&&&#    //
//    ...:^~~:.:!J777~^^:!7!!!!!!!!~.....:!Y~:::YJJ?::!75^~Y77.:775:...^~JG##&&&&&#&&&&###&&#&&&&#&&#&&&&B    //
//    .....:....~PJ?57Y575Y~:.:::....:^:..^5??~:5J75J7?!Y?J?!J:??7J.:!?Y?!JPB&&&&&&&&&&&&&&&#&&&&&###&&&#P    //
//    .....^~!~~75J7J7JY7?77!!^:^^:..:JJ7^.J?75YP55GBGGPGGPYY5J5JYY7J?J7.^JJJG#&#&&&&#&&&&&#&&&&###GG###G!    //
//    ...:^7Y5YJJYJ?????7?7~~^^:^:::..:!?J?7P5PPGPP5YJJJJJJ?JJYY5GG5?Y?^~?J7^7PGGGBB###&&&&#&&&&#GY?JYYJ^.    //
//    ....^?55?^^~Y?J5JPYPY^......~J?7~^!JJGBG5J??77??JJYYYYJJ????J5PPJ7?!:...^~!7?5PGGBBBGP5P5P5Y?777!~..    //
//    ...:~7?J7^^~J?~7^7!7!!~:.....^?5YJYGBG5?7???JJYYYY5555555YYJ??J5YJY~^~~~7~:~!JYYY5GGG5J?7?J?77!!~^..    //
//    ...:^^!JJ?J5JJ???JJJJJJ!..:~~^~75YYGPJ7?JJJYYJYYYYYYYYYYYYYYYJJ?Y5Y??JJ?~.:~!JYY5PGGGPJ7!7?7!~!~~:..    //
//    ...~7!:~!?77!7??!77^^^^:..:^7??J5BGY?7?JJYYYYYYYYYYYJJYYYYYYYYYYJYPYJ!^::..~?555PGPPGPY?JJY?7~~~~:..    //
//    ..:!7^..:PJY?P5PYPY!:...:^^^^!JJPPJ??JJYYYYYYYYYYYYYYJYYYYJJJ?JYYY5P?7??JJ!^J55YPPPP5J???JJ??~~~^...    //
//    ..:!7^:..~77!J?J??7?7777!!?????JYJ???77??JYYYYYYYYYYYJYY5PJ77?7J5YYYJJYJ7^..JPP5YYYJJ???JJJ77!~~^...    //
//    ........::~!7??J777777?7:..:^!?YJYYJ7::~J?JYJYJYYYYYYYJY5PJ?????55YY5~:.....?PPP5P55Y??JYJ?!!~^^:...    //
//    .......~YYY55??PJ7:...:.......^PJYP5Y7!7?JYY?YJYYYYYYYJYY5J?7???55YYY......:75PPPPPP5J??7!!~~^^:....    //
//    .......:!^7??!J77?!~~~7^......^PYJYYJJ?77??JYYJJYYYYJJJJY5YJ77?J55Y5P......:7Y5PPPGG5J!!!~^::::.....    //
//    ..........!YJYYYYYYYYJ!:......~PYJJJJJ???JJYYYJJYYYYJJJJ?JYYYYYYYJ?JG.....^!YPPPPPPP5?!!^^:........:    //
//    ..........~JYYYYYYYYY?:.......~BY?J?YYJJJJ?JYYYY555YYYJ??JY?JJJJ?7!?P..:^.^JP5P55P55J!^^...........:    //
//    ..........^7JJJJYYJJ?!........:G5?J??J?JYJY5PGGPGGGGGGPPGPG5P5J??7~Y5.....:?555PPGP57!7!:..!?~..~7!:    //
//    ..........^!??J?JJJ?^..........5BJ?J?Y5PGGGGG5YP5?5#Y?5#G5BBGG5J77~57.....:!7?JJJYY!:757:.^Y57~!?5Y^    //
//    ..........^!77777??!...........^G57?J5GGPBJPBY!GP!PBP!PYG?BGGGGJ7!!P^......::^^^^~~:..::..:!!7?7^??^    //
//    ....::^^^:~!!!!!!77~............~GY7J5GG7P#5!P#Y?##?5#G?P&BGGGPJ7~?Y......................:7JJ?^~5Y!    //
//    ....::^~~~!!~~~~!!!^.............~P55PGGPGBP5PBGGBBGGBGGGGGGGPY7!JP~................::^~~:..^::^!7?:    //
//    ....::^~~~~^^^^^^^^:..............^5#GGGGGGGGGGBPPB55PYYPYY5Y?77P#Y...............:^!!7?77^:::.!?Y!:    //
//    ....:::^^^^::::::::................:7G###P5YYYY5YY5YYYJJYYJ??7JBBJ:..............^7????JJJ?!!~^!!!.:    //
//    ......:^::::::::.....................:~?5BB#GJ7??JYYJJJJJ??JYPPJ^.................~??J?JYYYYYJ?PY5::    //
//    ......:^^^~:::::::..::::::..............:?7!BGJJJJ??777J5555P7:....................!?J?JYYYY??7JJ?::    //
//    .....::^~~~~77!~^::::..:::.............:!7?7B#JJJ5YYJ??JGGPY?:..................:..~??7JYYYJ7?JJYJ::    //
//    ......:!?!J7??77!^::::..:::........:^~?5BB##BPJJJYYJJ?J?777?J?!^:..................7???JYYJ??Y5555::    //
//    .....:^!7?????7!~^::::::::::...:^!JYGBBG55YJJJY55P55555YJJ??J????!::............:::?JJJYJ?7JJJ555Y::    //
//    .....:^~77~!7!!~~::::::::::..:~?GB#BPY???JY555555P5555555555PP5YJJJ7:.........:?YYJYJJJYJ7JY5PGP5Y^:    //
//    .....::^77^!777!^::::::::::^75B#G5YJJYY5YY555555555555555YYYPGGP5JJY5Y~........^77?YYYYYJ?5P##B##P~:    //
//    ......:^!?!!!7?7^::::::::~YG##B5J5P555YY???55555555555555555PPPPGPYJJ5P!.......:~!J555YY?75#&BP#&G!:    //
//    ......::^~~!~~~^::::::::JB#GP5YJY5555YJJJYYYY5555555555PP55555PPGBPYJ?YG7....:?5GBB#BBPY!!PPG#&@BP?^    //
//    ......::::::::....:::::?##P55YY5P5555JYYY5P5YYY5555555P55YJ55555PGG5YYP5P~...!#&&&&&#&#J::!Y#&&@GG!^    //
//    .......:..:::::...::::^[email protected]^..!&&&&&&&&#? ..!&@@&GP^:    //
//    ......:::::^^^~^:::::.^B&55YY?YYYJJJJJYYYYYYYY5PGG55555JJ55555Y5Y5PP5YJ?5G~..7&&&&&&&&#!::^[email protected]&PG&B~:    //
//    ....:~~!7^^^^^~^:.....^B#YJYJJYYYYJJJYYYYYYYYYYYY555555J7Y55555555PPP5J?PB?^.!#&&&###&&P?~~5#&##&P^:    //
//    ...:~??JJ7!~~~~~^...::^BBJ?J?Y55YYYJYYYJJJYYYYYYYY55555PPPPPP55555PPPPY?P#7!~~5########PY77PPGGJ5!.:    //
//    ....^!7!77?7!!~~^.....~#BJ??JY55YYYYYYYYYYYYYYYYYYYYY55PPPPPPP5555PPP55JYBYJ??YBBBBBBBGJYJYJ7!Y??:.:    //
//    .....:::^~!~^^^^~^:...7#BJ7YYY5YYYYYP5YYYYYYYYYYYYYY555PPPPPPPP55PPPP5YJY#PPPPPGPGGGGPPP557~!Y#G5^.:    //
//    .........:::::^~~:....J&G??Y555YYYY5PP5Y55555YY5YYYY555PPPPPPPPP5GBBP5YJY&BPGGGGGGPP5555YJ?5##5P&5::    //
//    .....:^....::~7!!^...:P&P?J5P55YYYYYY5555555YJ55YPPP555PPP5555PPPPGBP55JY##GGGGPGGGGGGPPJYP5G&##B!.:    //
//    .....^7~:.:::7^:::^^::Y#5JY5P55YYYYYYYYYY55YJJY55555555PPPPPP55555P5555JJB&GGGGP5PPGPPPBPYPPPPGGPY::    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract INKS is ERC721Creator {
    constructor() ERC721Creator("30Inks", "INKS") {}
}