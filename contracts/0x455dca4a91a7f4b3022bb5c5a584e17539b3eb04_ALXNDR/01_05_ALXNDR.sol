// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alexandre
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ::........     .^^^^^^^^7P!7YPYJJYYYPYYYJ55YYB#BBGGP5GGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPG575######BBBBBB    //
//    :::......      .^^^^^^^^7G77YPYJJYY5PYY5J55Y5B#BBGGP5GGGPPPPPPPPPPPPPPPPPPPPPPPPPPPGGY7P######BBBBBB    //
//    :.........     .^^^^^^^^!G77YPYJJYY5PYY5J55Y5B#BBGGP5GGGGPPPPPPPPPPPPPPPPPPPPPPPPPPGGJ?G######BBBBBB    //
//    ::........     .^^^^^^^^!G?7YPYYJYYYPYY5J55Y5B#BBGGP5GGGGPPPPPPPPPPPPPPPPPPPPPPPPPPGP??B&&####BBBBBB    //
//    :.:.......     .^^^^^^^^!P?7YPYYJYYYPYY5J55Y5B#BBGGP5GGGGPPPPPPPPPPPPPPPPPPPPPPPGGGGP?JB&&&###BBBBBB    //
//    :::::......    .^^^^^^^^~P?!YPYYJYY5PYYYJP5Y5B#BBGGP5GGGGPPPPPPPPPPPPPPPPPPPPPPPGGGG57Y#&&&####BBBBB    //
//    :::::::::..    .:^^^^^^^~PJ!YPYYJYY5PYJYJP5Y5B#BBGGP5GGGGPPPPPPPPPPPPPPPPPPPPPPPGGGG57P&&&&####BBBBB    //
//    ^^::::::::......^^^^^^^^~PJ!YPYYJYY5PYJYJP5Y5B#BBGGP5GGGGPPPPPPPPPPPPPPPPPPPPPPPPGGGY7G&&&#####BBBBB    //
//    7!!!^:::^~~!!!!~^^^^^^^^^5Y!YPYYJYY5PYYYJP5Y5B#BBGGP5GGGGPPPPPPPPPPPPPPPPPPPPPPPGGGGJ?B&&&&####BBBBB    //
//    ?777!~^~!!7777?7^^^^^^^^^5Y!JPYYJYY5PYJYJP5Y5B#BBBGP5GGGGPPPPPPPPPPPPPPPPPPPPPPPGGGP?J#&&&&####BBBBB    //
//    77???77!!!77???7^^^^^^^^^Y5!JP5YJY55PYJYJP5Y5B#BBBGP5GGGGPPPPPPPPPPPPPPPPPPPPPPPPGGP?Y#&&&&###BBBBBB    //
//    77?JJ??77????J??~^^^^^^^^Y5!JP5YJY55PYJYJ55YPB#BBBGPYPGGGPPPPPP5?YPPPPPPPPPPPPPPPPG5?P&&&&&###BBBBBB    //
//    77??JJ?????77???~^^^^^^^^J5!JP5YJY55PYJYJ55YPB#BBBGP5GP5PPP555J!7GPPPPPPPPPPPPPPPPGY?G&&&&####BBBBBB    //
//    ?77??77!!7!!7??7~^^^^^^^^?P!?55YJY55PYJYJ55YPB#BBBGPY57!!!7?JYJJBGPPPPP5YJJJYPPPPGGJJB&&&&####BBBBBB    //
//    7!!!!!!!!~~!!!77~^^^^^^^^?P!?55YJY55PYJYJ55YP##P555YYJJ?7?YG#&&##BGPPYJ????75PPPPGPJY#&&&&###BBBBBBB    //
//    !!!~~!!!!!~~~!77~^^^^^^^^7P!?55YJY55PYJYJ55Y5GY5G5Y555PG5PPG#&&&#BB#GYYYJ??JPPPPPGP?5#&&&&###BBBBBBB    //
//    ~~~!!7777!!!!!7?!^^^^^^^^!P!?55YJY55PYJY?55Y5J~7Y5YJJ????YPG#&&#BPPGPPPP5JJPPPPPPG5JP&#&&&###BBBBBBB    //
//     ...:::::^^~~!77!^^^^^^^^!P!755YJJ55PYJY?5YJY5~~!JJJJ????JPG#@@&GPPPGBPP55PPPPPPPGYJB&#&&&###BBBBBBB    //
//    ^:::....      ...:^^^^^^^~P7755YJJ55PYJJ?YYYPB?^~!7?JJJ????JP&&&#PPP55PGGPPPPPPPPPYYB&#&&&##BBBBBBBG    //
//    777!~~~~~^^^^^^::^^^^^^^^~57755YJJ55PYJJ?555PBGY7777???7777?J5PPP5YYPP5GPPPPPPPPPPY5#&#&&###BBBBBBGG    //
//    777!~^^^^~~~~~~!!^^^^^^^^^5?!55YJJ55PYJYJ555PBBBPGP?^~!7!!7??JJJJJY55PPPPPPPPPPPPPYP&##&&###BBBBBBGG    //
//    !!!!~^~~~~~~~^~!7^^^^^^::^Y?!Y5YJJY5P5JYJ555PBBGBB5~:::^[email protected]#PPPPPPPPPP5YG&#&&&##BBBBBGGGG    //
//    !!7!~^~!!!!!~^~!!^^::::::^Y?!YPYYY55G5JYJ555PBBBBY^.:::^~~!7??JJYY55PGGGPPPPPPPPP5YB&#&&&##BBBBBGGGG    //
//    !~!!~^~!!!77!^~!!^^:::::::J?!YPYYY55G5JYJP55PB#B?:.:::::^~!77?JJJY5555PPPPPPPPPPP55###&&&##BBBBBGGGG    //
//    !~~!~^~!!!77!^^77~:^^::::~??!YP5YY55G5YYJP55P##Y:::::::^^~!!7?JJYYYY555PPPPPPPPPP5P###&&&##BBBBGGGGG    //
//    7777!^^~~~~~~^^!!^:::^~!!!!?Y5P5YY55GPYYJP55G#B7.::::::^~~!7??JJYYYYY55PGGPPPPPPP5G&##&&##BBBBBGGGGG    //
//    ?777!^^~~!!!~::....^~!!!7J5555YY55PPGPY5JPP5G#B7.:::::^^~!!7??JJJJYYY55PGGGPPPPP55B&#&&&##BBBBGGGGGG    //
//    ~^~!!^^~!!~:... .^!!!!?Y555YYYY555PPBGPPYPP5G#P^.::::^^~~!7??JJJJJJJY55PGGGGPPPP5P#&#&&&##BBBBGGGGGG    //
//    .:~!!^:^^.. ..:~!^~7J555YYYYY5555PPGBGPG5PPPGG!..:::::^~~!77??JJJJJJY5PGGGGGPPPP5G#&&&&&##BBBBGGGGGG    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALXNDR is ERC1155Creator {
    constructor() ERC1155Creator() {}
}