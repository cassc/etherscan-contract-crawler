// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Santa Does NFT Miami
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    Dew_uc_me Original @2022 (Dewucme)                                                                      //
//                                                                                                            //
//                                                                                                            //
//    !~:..........    .:^~!7?Y5PPGGGGP5YJ??JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ??77!!!~~~~^^::::::::^^~    //
//    ^^.......     ..~:.^:.:!?Y5PPGBBBGP5JJ?JJJJJJJJJJJJJJJJJJJJJJJJY5555YJJ?JJJ?????7!~~~~^::.:::::::^^7    //
//    !!~^:.    .:^~~.!: ^^!7JJY55PPGGGP55J????????????????J????JJYPGBBBBBGGPY????????!~^::^:..:::::^^^^!J    //
//    777!~~~^^~!!~~^.~..77~!?Y5PPGBBBBGGPJ???????????????7!!77?JYPGB##BBBBBBBG5J??77!^::..::::::::^^^^?YY    //
//    ????77???!~^^~~.?^.!..^7?JY55PPGGPPP5?????????????!:.....:^!?JYPGGB########GJ~~^^:::::::::^^~!777JY5    //
//    !^:~!!!!777?JJ?:?^.7??JJYY5PPPPPPPP55???J????????7: ......:~7!!!!!7?J5GBBB###5^^^:::^^^^^^^^~?Y55YYY    //
//    ?!:!77?JJJJJ?77^7^:?^:~?JJYYY5PGGPPP5??7?Y?7J???7!........:~77!!!!!!!!7?JYPBB#Y^^^^^^^^^^^^^^!?JYY55    //
//    555YYYJJ?7777!7^J~.~~7?JJJ??JJY55555577?7JY7?Y?777:.^^~~^~~!???777777777?J5PGBB7^^^^~~~!!7?7?J?77?JY    //
//    Y55PP5?7?J??J7?^?^:JJ7?Y55555PPGP5555Y?777P?7YJ7777!!J7!!?YPPP555YYYJJ???JY5PGB5~~~~~~!7JY555PPPP555    //
//    YYY5PPPYJJ???7?!Y~:7^^!?JYYY55PPP5YPPGGPY55775Y777777!~7??YPGGGGPPPPP555555PPGBG!~~~~~~~!!7JYYPPPPGG    //
//    5YJ?YY5Y?YJYJJJ~Y?^?JJJYY5555PPP555PGGGPGBPY55777777?7?55YYPGGBBGPPBBG55GPPGPJPB?!!!!!~~~!!7??55PPPP    //
//    55J7J?JYJ5555PPYYJJY7!?JY55PPPPYYPP5PP7!7?YJ?7777777J?PGBPYYPGBBPPPBBBPPGPPY!^!?7!!!!!!!J5PPPGGGPPPP    //
//    PPJJJJY5555555PG5Y?Y7~7?YJJJYYJYPPP5J~^~!!!!!77777!!7?JYJ?7JY555555PGGGBBGPY::~!7??!!!?Y5555YY55P55P    //
//    ?Y5P5Y5YJ??77?YPGG5Y5JYY5555P55PP55Y?::^~!!7!!!!!!!!~:~!^:^~!7??JJJY55PPP555?7JY55?!!7??77777777?7?5    //
//    ^~J55J77777?JJY?!YPPP5?JJ5PPPPP55YYYJ^^~7J557!!!!!!^::~^:^^~!!!!!77777JYYYJ??7777!~~~!~!!!!!!!!!!!7Y    //
//    ^..!YJJYYYYYY???^^75PP5YY5PPPP55YJ7777J5PPPJ~!!!!!!~~: ...::^^~~~~~!7???!~^^::::~7J55P5Y?!!!!!!!!!!?    //
//    :^ ~JJYJ?77!!~!??!~!7!!77?JY555P?~?55PPP5PJ^^~~~~~^:. ....:::^^^~~!77!^::...:~?YPGBBBBBBBPJ!!!!!!!!?    //
//    .: ~7!!!!7??JJJ??!^..::.:!???J5J!YGP55555J!~~~~~^:........::^^~!7!!^:.....:!JPGBBBBB#######P7~!!!!!7    //
//    .: ~?JJYYYJ7!~!~^^~7?JJJ55Y5JY5Y555YYYYJ7~~~~~~:.   ....::^^^!!!~:......^!JPG###############G?~~~~~7    //
//    .: !J??7!!~. ~JJ???JJJJYYJJJJ?55YYYY?~^^~~~~~~^     .:::^^~~!!^.     .:7YPB##########&########J~~~~7    //
//    .. ^!~!!77~:~7?YP5JYJJJJYYYYYJJYY5Y5Y~^~~~~~^^:...::^^^~~~!!~:      :~J5G#######BB##&&&&&&&&##B7~~~!    //
//    .. ~??JJJJ?!JYYYJJY5YYYYJJJJJJ?J?YYYJ~~~~^^^^^..^~!!!!!7777~:.    :!J5GB########BBBB#&&&&&&&&##G~~~!    //
//    .: ~77!~!~~^7JJJJJJYYYJJ???????J?JP5J~^^^^^^^::~!??7???J?7^:.   .^?YPBBBB########BBBB##&&&&&&&##?~~!    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SNM is ERC1155Creator {
    constructor() ERC1155Creator("Santa Does NFT Miami", "SNM") {}
}