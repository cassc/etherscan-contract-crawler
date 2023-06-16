// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Sacred Enochian Texts
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                               //    //
//    //                                                                                                               //    //
//    //    @[email protected]@@@&#GPPPGB##&&@@@@@@@@@@@@@&GGGGGGGGGGGGGGGGGGGGY                                         //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#P??JY5P5YYYYYJJJYPGB&@@@@@@#.                                   //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BP5J?7?Y5555Y5PGGBGGP5YYYJ77P&@@@B                                    //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BYJJYJJJYYYYYY5GPP55PPPPPGGGBBG5YJYPG!:                                  //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GJ!J5YYYYYYYYYYYYYYYYYYYYYYYYYYY5PGGG577?Y?^                               //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]?.                            //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@#J7?Y#&5YYYYYYYYYYYYYYYPGBBGGGGGGGP55YYYYYYYYPBY~P#5G:                           //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@BJ??YYBB5YYYYYYYYYYYYYPB##BGP5YYYYYYYYYYYYYYYYYY55Y!#J#!                           //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@G?GYYYGG5YYYYYYYYYYYPB#BP5YYJJYYYYYYYYYYYYYYYYYYYYYYJG&Y:   ^                       //    //
//    //    @@@@@@@@@@@@@@@@@@@@@#5JB5YYY#55YYYYYYYYYP#BPYJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYBPJJ?7~7J                      //    //
//    //    @@@@@@@@@@@@@@@@@@@@5?5BPYYY5BYYYYYYYYYP##5YYYYYYYYYYYYYYYYYYYYYYYYYYY55YYYYYYGP5G5!?:                     //    //
//    //    @@@@@@@@@@@@@@@@@@@&!#5YYYYJP5YYYYYYYY5#PYY555555555YYYYYYYYYYYYYYYYYP55YYYJ5B55#P5B?~                     //    //
//    //    @@@@@@@@@@@@@@@@@@@&!B5YYYYY5YYYYYYYY5PPPPPP55YYYYYYYYYYYYYYYYYYYYYYYYYYYYYPGY5#PYY#Y!.......              //    //
//    //    @@@@@@@@@@@@@@@@@@@@P?#P55YYYYYYYY5PP555PPPPPPPPPPP5YYYYYYYYYYYYYYYY555PPPBG5BB5YYY#YP&####&J              //    //
//    //    @@@@@@@@@@@@@@@@@@@@@!B!^7Y5YYY5PPP555YYJ?77??Y5PPPGGGPPPPPGGGGPPPGPPPPGGGGGB#G5YYY#Y&@@@@@@Y              //    //
//    //    @@@@@@@@@@@@@@@@@@@@@Y5^^^^JGPP555YJ7~^^:^!7????77JPB#BGGP555PPPPP555YJ?7?JY5GPPBPP#[email protected]@@@@@@Y              //    //
//    //    @@@@@@@@@@@@@@@@@#BGBY5~^^^^5P5YJ!^^^^^7P#&@@@&&##GJ7JGGGPPPG55GB#&&&##BGY!:^!5G5#&[email protected]@@@@@@Y              //    //
//    //    @@@@@@@@@@@@@@#5J7!!!7G!^^^^^5P!Y~^^^^5&&&#BGP55PB&@#?^7Y5YJ7Y#@@&#BBGGG#@&5~:^JGGGB&@@@@@@@Y              //    //
//    //    @@@@@@@@@@@@&YJ?~^!JJYG?^^^^[email protected]#55JJJ?JJJJG&&&7::^^:?&&PP5YJJJJJ5#&@G!!~!PGPY5G&@@@@Y              //    //
//    //    @@@@@@@@@@@&!JJ^JG5?~!BG^^^!?^!J5YJJJ&&[email protected]#&PY?5JY7JY5JJG#@G5PYB7:^7JYG&@@Y              //    //
//    //    @@@@@@@@@@@@G?JB#7^:~Y#J^^^~7^7?7!7?J#@&PGGPJ?7?5J7P&&[email protected]~!?P77P#@PYP#&BY~:7B5&@@Y              //    //
//    //    @@@@@@@@@@@@@B!&!^^?B5~^^^^^^^~^^^^^^[email protected]@@@&&&&&&##@@5^^^Y7:7#@&&&&##BBBGG&@P~^^?#BPB5#5&@@@Y              //    //
//    //    @@@@@@@@@@@@@#!G^^7&?^^^^^^^^^^^^^^^^^~JG&@@@@@@@&#P7^^^^~~^^~5&@@@@&@@@@&#Y^^^^^!#G?##[email protected]@@@Y              //    //
//    //    @@@@@@@@@@@@@#!G^^55:^^^^^^^^J^^^^^^^^^^^!?Y5555J7~^^^^^^^^^^^^~JP###BGPY?!^^^^^^^[email protected]@@@Y              //    //
//    //    @@@@@@@@@@@@@@7G~^B7^^^^^^75P&5?777!!!!~^:::^^^^^^^^^^^^^^^^^^^^^^~!?JJ?7?~^^^^^^7#[email protected]@@@Y              //    //
//    //    @@@@@@@@@@@@@@5JJ:P7^^^^^^~?YPB#######&#G5J7~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!P&@[email protected]@@@Y              //    //
//    //    @@@@@@@@@@@@@@&!G^~PP7:^^^^^^^~7JPBBBBBB#&&&#BG5Y?77!!7777777777!!!!~~~~~~!7?YG#&##[email protected]@@@@Y              //    //
//    //    @@@@@@@@@@@@@@@5JG^~PB7^^^^^^^^^^^!JPB#BBBB##&&&&&&&&&&&&&&&&&&&&&######BB##&&##[email protected]#@@@@@Y              //    //
//    //    @@@@@@@@@@@@@@@@YYPJ?G5J!^^^^^^^^^^^^~?PB###B##############&#BBBBBBBBBBB###&&#[email protected]#@@@@@@Y              //    //
//    //    @@@@@@@@@@@@@@@@@BP555BB5J!^^^^^^^^^^^^~?YPBB##BBBBBBBBBBBBBBBBB###########P?~^^^!&Y&@@@@@@@Y              //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@B5J^^^^^^^^^^^^^!7PBPPGGBBBBBB##&&&####BBBBBBGPY?~^^^^^^[email protected]@@@@@@@Y              //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@#P5!^^^^^^^^^^^Y^~?YPPGPGGGGPPY?7???JJYYYJ?!~^:^^^^^^^7GP&&&&&&&&@J              //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@@&BPY?!~^^!7!!7PY7!!!!7777!~^^:^^~!7?JJJ?7??777777!!?YPJ~:::::::::.              //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BPJY55GGGPP555PPPP555YYYYYYPGB##BGPP55555555555YJ?^                          //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P^^!?JY555YYYYYYYYY55555555YYYYYYYYYYYYYYYY7~.                             //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y^. .^77?JYYYYYYYYYYYYYYYYYYYYYYYYY555BB!!!                               //    //
//    //    @@YUMMY SPROTO [email protected]@@@@@@@@@@J?&G: .J?7!?YYYYYYYYYYYYYYYYYYY55555YJJ#&B!77                           //    //
//    //    @@@@@@I WANT TO EAT YOUR [email protected]@@P^&&@G..JYYYJJ?YGGP55YYYYY55PPP5YYJJJJYYG&&&J7J^.                          //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@@@#5?7G&&&@7.JYYYYYYJJY5PPPPPPP55YJJJJYYYYYYYP&&&&5!77                           //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@@@G?!?G&&&&&&5:YYYYYYYYYYYJJJJJJJJJYYYYYYYYYYYY5&&&&&B!~.                          //    //
//    //    @@@@@@@@@@@@@@@@@@@@@@@@P7!JG&&&&&&&&P~YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY#&&&&&&BGPYJ7^:                    //    //
//    //    @@@@@@@@@@@@@@@@@@@@@&P77YB&&&&&&&&&&G7YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYG&&&&&&&&&&&&&#G5J!:               //    //
//    //    @@@@@@@@@@@@&BGPPP555JJP#&&&&&&&&&&&&G?YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5&&&&&&&&&&&&&&&&&&&?              //    //
//    //    @@@@@@@@@@#GPPGB##&&&&&&&&&&&&&&&&&&&G?YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY#&&&&&&&&&&&&&&&&&@Y              //    //
//    //    @@@@@@@@@@&#&&&&&&&&&&&&&&&&&&&&&&&&&P~JJYYJJJ??77!!~~^^^^^^~~!!7??JJJJJ75&&&&&&&&&&&&&&&&&&Y              //    //
//    //    @@@@@@@@@@@&&&&BGGGG#&&&BGGG&&&&&&&&&P  .::..                      ..... ^&&&&&&&@@@@7^^^^^^:              //    //
//    //    @@@@@@@@@@BYYJ!... [email protected]@B.  .B&&&&&&&&P                                   .G&&&&&&@@@@~                     //    //
//    //                                                                                                               //    //
//    //                                                                                                               //    //
//    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ENOCHIAN is ERC1155Creator {
    constructor() ERC1155Creator("The Sacred Enochian Texts", "ENOCHIAN") {}
}