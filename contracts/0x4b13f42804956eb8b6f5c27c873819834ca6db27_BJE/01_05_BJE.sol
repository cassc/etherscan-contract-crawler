// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bocagrandiart by Jennika Embryo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BG5YYJJJJJJJJJJJJJYYYYYY55GB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#PY7~^::........................::^~7YP#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@&GY7^:......:::.:...............:...:.......:^7YG&@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@#57^.....:........::::::~^:^?7::J5^:!Y~.:~:.........^75#@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@#Y!:...:....::!7?YYPGBG####@###@@#B&@#B&@#GB&P77J~....:...:[email protected]@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@&5!. ..:...:~YPG#@&@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@#P55^...:...7JP&@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@GJ?JYJ^..:[email protected]@@@@@@&#BGGPP555555JYB5JJP7YPPPPGB#&@@@@@@@#PYJ:..5P77:5&@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@##7~P!^[email protected]#@@@@@&#[email protected]^!~^^~~~!!!~!!7?55#[email protected]@Y^~&J?! !!J#@@@@@@@@@@@@    //
//    @@@@@@@@@@&Y:[email protected]:[email protected]?#@@@&PJ7!!!~?!!~~!~~!77?~#@~^~~77B7~J?~5!~?.GG:[email protected][email protected]?..P5 ^5&@@@@@@@@@@    //
//    @@@@@@@@@G~....^@5!JBYJG#BJ!YY?!~^B5~7^P?^[email protected][email protected]?Y?JB^P5:G&[email protected]!!#[email protected]^BP.?:[email protected]@@@@@@@@    //
//    @@@@@@@&?..::...BY5#BP5B?^~G#?5Y:[email protected]!YJ7&~5B:[email protected][email protected]!7&?!?5!#Y~5#?~5&~?YGYP&7B?!?J!^...?&@@@@@@@    //
//    @@@@@@#~..::.^[email protected]@[email protected]?~PY:???7&77!~~^YB7^^^:[email protected][email protected]?:[email protected]!~7~7?J???7Y?G?^[email protected]::..~#@@@@@@    //
//    @@@@@G^.:::[email protected]#[email protected]?:??J?YY7!!^::::.^::::::!?!!~B~::PJ~::^~!?JYYYY7JG?!!!~Y#@@@&GJ..::.^[email protected]@@@@    //
//    @@@@G:.:::.!5#@@BGPJ7~?#Y7JYY5Y?~^::::~7?JYYYJ7^::::::!7?JJJ7~^::::[email protected]@@@#!^:::.:[email protected]@@@    //
//    @@@B:.:::[email protected]@@@@5~77?PJJYYYY?~::::~JPP5J?77J5GGPYYYPGGGPYJJYPP57^:::^!?YYYYG#[email protected]@@@&P:.::.:[email protected]@@    //
//    @@#^.:::.!P&@@@&J!!!:JG5YYYJ!::::!5G5!:.:^~^::!PGGGP7^~YY~~!!!!?PGJ~:::^[email protected]@@@&J7:::.^#@@    //
//    @@7.::::[email protected]@@@&J!!~7GPYYYY7^:::~5BP!^[email protected]@@@@5..::[email protected]@    //
//    @P.:::::Y&@@@&J!!~~BGYYYJ7^:::7GGGYYPGGGGGGGGGGGGGGGGGGGGGGGPGGPPGB######[email protected]@@@#P?:::[email protected]    //
//    @~.:::.^#@@@@Y!~^7&GYYYJ7::::JBGGGGGGGGGGGGG5Y?7!~~!7?J5PGGGGG5G##BPYYY5PB##[email protected]@@@&!.::[email protected]    //
//    G.:::.^G&@@@P!!~~#BYYYJ7::::YBGGGGGGGGGGPJ!:            .^?5B5B##5??JJJJJJYG#[email protected]@@@BG!.:.G    //
//    ?.:::[email protected]@@@#!!!^G#5YYJ7^:::YBGGGGGGGGG5!.              .:~~!5Y##G7YY5PGP5YJJG#BYBY?JP!!!7&@@@@5^::.?    //
//    ~.::.^[email protected]@@@J!!~?&PYYY?~:::?BGGGGGGGGY^                ~YPPPPP5YG#JJYG#GBP5YYY##[email protected][email protected]@@@#GJ:.~    //
//    ::::[email protected]@@@B!!!~5BYYYJ!:::~GGGGGGGG5!^~7??7~:         .GGY55YJYGYP#GGB#GBPY5Y5##YPPY!P#!!!!#@@@@Y^:::    //
//    ::::[email protected]@@@5!!!?5PYYY?^:::5GPGGGGP77JPB####BGY~        YB5^.!P7J#?Y??5BGP55YYG#[email protected][email protected]@@@&P~.:    //
//    :::::[email protected]@@@J!!!PGYYYJ7:::^BGGGGP7.?5#&B555PB#&B:        ~~  !P?5#77^!JP55YJJP##YPPJY7!&B!!!7&@@@&7:::    //
//    ~.:.:G&@@@?!!!P5YYYJ7:::^GGGBP~ ^P##GYYY?~JB&P.  ..:^^~!!7JYJPB?YPPP5YYJJYB#B5PJ!?YYYB#!!!!#@@@@P^.~    //
//    ?.::[email protected]@@@[email protected]?JYY?~:::JBPGGG55P&#BYYY?:.7?~~7J5PPPPP5YYY5P5?Y5JJJJJYPB#BP5Y!:!JY!!BB!!!7&@@@&!..?    //
//    G.:.:P&@@@#!!!!GPJYYJ7^:::5GGGGGGGB##BP555YY5PGGB##GGGPPGGGPPPPPPPGGBBBGPPGY!::^?YYYY&[email protected]@@@&?..G    //
//    @~.:.:[email protected]@@@P!!!?&#PYYJ7^:::YBGPGGGGGB####B####BBGGGGGGGGGGB###BBGGGGPPPGGB5::::[email protected]@@@[email protected]    //
//    @P.:.~G#@@@@J!!!J&BYYYJ7^:::7PGGG5^^?5GBB#BBGGGGGGGGGGGGGGPPGGGGG5J!7PGGG?:::^7JYYYP#[email protected]@@@#[email protected]    //
//    @@7.:::[email protected]@@@&?!!!?&Y!YYJ?~:::^JPGG?:  :~!?JYY55555PGGGGGGGGG5J7!:  :?GGY~:::~?JYYY?7?!!!J&@@@@[email protected]@    //
//    @@#^.::JG&@@@&J!!!7G#5JYYJ!^:::^75GG5J!^:.       .?GGGGGGGGY:  .^7YGPJ~:::~7JYYYYGP!!!!?&@@@&P^.^#@@    //
//    @@@B:.:[email protected]@@@@5!!!!5B?JYYY?!^::::^7YPGGGP5YJJJJY5PGGGGGGGGGP5PPP5?~::::~7JYYYYPY^!!!!Y&@@@&Y..:[email protected]@@    //
//    @@@@G:.::?Y#@@@@G7!!!7P#P~JYYJ!~::::::^!7JY5PPPGGGGGGGPPP55YJ?!~:::::^[email protected]@@@&Y^.:[email protected]@@@    //
//    @@@@@G^.:..J&@@@@&5!!!!75GG5?JYYJ7~^^::::::::::^^^^^^^^^::::::::^^~7?JYYYY5PG5~~!!!Y#@@@@#!..^[email protected]@@@@    //
//    @@@@@@#~..:^~?&@@@@#Y!!!!!JPY55Y?YYYJ?7!~~^^^^:::::::::^^^^~~!7?JYYYYYY5PG57^[email protected]@@&&Y~..~#@@@@@@    //
//    @@@@@@@&?....:PP#@@@@&P?!!!!7?5Y?P5YYYYYYYYYJJJJJ???JJJJJYYYYYYYYY5PPPPY!~!!!!75#@@@@&P~...?&@@@@@@@    //
//    @@@@@@@@@G~..::.!&&@@@@@BY7!!!!!7?^7PPPP555YYYYYYYYYYYYYYY55PPPPP5YJ7:~!~~!7YG&@@@@&[email protected]@@@@@@@@    //
//    @@@@@@@@@@&Y^...:[email protected]@@@@@@#PJ7!!!!!!!!^~JY55PP5PPPPP55555Y7??7!^:!!!~!7J5B&@@@@&BJ~...^Y&@@@@@@@@@@    //
//    @@@@@@@@@@@@#J^....:[email protected]@@@@@&#G5J7!!!~~!!!!!~:~!!!!^:~!!~^~!!!!!7JYPB&@@@@&&BY7:...^J#@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@#Y^[email protected]@@@@@@@@&#GP5YYJJ??777777777??JJY5PGB&&@@@@@@@#PJ!:....^Y#@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@&P!:......:55?5&@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@&&#GY?!:.....:!P&@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@#Y!:.......:?J~7#[email protected]@&&@@@@@@@@@@@@@@@@&&&BPP5?!~^.......:!Y#@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@#57^.........^^.:?J^^?G?!JBY7?557!?J~^!~:...........^75#@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@&GY7^:......::.........:....................:^7YG&@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#PY7~^::............:...........::^~7YP#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BG5YJ?7!~^^^^::::^^^~!7?Y5GB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BJE is ERC721Creator {
    constructor() ERC721Creator("Bocagrandiart by Jennika Embryo", "BJE") {}
}