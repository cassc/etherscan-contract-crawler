// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BabySlayr
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ###########BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#BBB###############&&&&&#########    //
//    #########7~^!7:^!7??7~:7?7^^^^^^^^^^:^^^::^^^^^^^^^~~~~~~~^^^!777!~^!77~~~~~~!~~!!!!!777??Y#########    //
//    ########G::.YGJB&&&&&#PBBB^:::.J7.~?5PGGPJ~55G^::::::::.!P^YB&&&&&BYYB#!:::~Y:!J5PP5J~~55?.P########    //
//    ########5:::[email protected]@&##BGGB&@#~::::.G5P&###&##&#&#J:::::::::.?&#&#BGBGB&&&&7::::?&[email protected]&&&#&@@##G~.5&#######    //
//    #######&J:::.7GYJ5GJJJYB?.::::[email protected]#P#@@@@P5G&J.::::::::::!#&@@&GB5Y55#J.::::^B#[email protected]:::5&#######    //
//    #######&?::7?~^!YBB?JY?^.:::::::[email protected]@@@BPP7::::::::::::.~5&@@&@#YJJ~:::::::^?J?P5!?JJ7::::Y&#######    //
//    #######&J.:GPGB7J#&#PB7!7:::::::.^?&@BYP&@Y..:::::....:.:7#@[email protected]@P5J.:::::J!7Y~J&&BPP?~~:::?&#######    //
//    #######&Y.:^~^5P~Y5!PG7GP.::::::.?#&@[email protected][email protected]#[email protected]@PBB5G::::?JJ#P7P57P&PBP:::?&#######    //
//    #######&5::::.G! JY~JB!7!::::::::^^!&@B?GJY#####BBBBBBB##[email protected]@G?G!7#~::::.~B^ Y?:J#J?J.::7&#######    //
//    #######&Y::?J^B~!5G?7~G^Y7:::::::..:[email protected]@?PB55YJJJJJJJJJJJJ5GBPJB&&G#7.~^:::5~5?~7YY?!~G^75::7&#######    //
//    #######&Y..?BP&#BB#PBB#GG!::::::.~5&&GYYPYJJYY55PPPPPPP55YYYY5YJ5G#@G7:.::PG#B#G#GG&B#5!B::7&#######    //
//    ########5:::P&P5YPPJY5B&J.::::[email protected]#[email protected]#?:.^B#P5YG5Y5P#&G!::7&#######    //
//    #########7:::!J??PG?JY5Y::::.:[email protected]#[email protected]!.:7??JB5JJYPG~:::7&#######    //
//    ########&?::::.?BP&GPJ^.:::.^[email protected][email protected]@Y..^:5&GPP7~:::::7########    //
//    ########&?.:::::GPP~Y#7.::.~&@[email protected]@J 75^B7!#7.:::^:7########    //
//    ########&7.J?.:Y?75~7^57..^#@[email protected]@~ YPY^?~P7^J^::7########    //
//    #########!.P?.5#5B#GPYJB~:[email protected]?J7G&@&&&&&&@#PJJ5YYYYYY55JJG#@@@&&&&@@@BYYY7#@GJG&BGG5YG:#~::7########    //
//    #########~.7GG&#BPPPPBB#G7&&[email protected]@Y~^::::^[email protected]@&[email protected]@@[email protected]@[email protected]@BGGBGB##&55:::7########    //
//    #########^:.7#5J??GJ777P!!##[email protected]@Y~^^^^[email protected]@@[email protected]@@P!!~~!!7J#@@[email protected]@Y!?G7!7YBG::::7########    //
//    ########B^::::!?YJGJJYG7J?#B75?P#@@@&&@@@@#GYJ55YYYYY55JJPB&&&###&&&#[email protected]@GYYBJYBGB?::::7########    //
//    ########B^:::.!PJ7P5?BP7G5##[email protected]@?!PGY##55J5?::7########    //
//    ########G:::::P7JP:7Y75B?J#&?Y55YYYJJJJJJJJJJJJJJJJJJJ???????7777?77JG#[email protected]@?JP7J55!B::~::7&#######    //
//    ########P:::.YY.?J5B?~^YJ:[email protected][email protected]~?#@5Y!GG77B!JJ::::7########    //
//    ########P::::#[email protected]#[email protected]&!7##J&J#[email protected]&[email protected]@[email protected]&@@JGBB#GB#G5B::::7########    //
//    ########P::::P&[email protected]??&@J!&@Y&[email protected]@P&@@#[email protected]@[email protected]@@@@@@@@5#@YBJY#@@#BG5YPYYPG&G::::7########    //
//    ########P:::::???755~7J?^..^&@[email protected]#[email protected]@G5#[email protected]@@@@@@@@@@@@@@@@@@@#[email protected]#@@5^5?!~P?!!J5~::::7########    //
//    ########P:::::..:J&#55G:.::[email protected]#[email protected]@&[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@Y..:~!?#GGG5.:::::?&#######    //
//    ########5.^^.:?J?J?YP5B?..::[email protected]#[email protected]@PGGPY&@[email protected]#@#[email protected]@@#5#&5?7^Y#@@&?..:..!P#BPG5::::::Y&#######    //
//    ########5.!BJPPBP^GY77YBJY~..:[email protected]@[email protected]&Y&[email protected]#JY77J77#@@@5^.^7^Y5JYB^J#GP^!:::Y&#######    //
//    ########P.^Y!!!!B~G^.!J?YYJ?:..?#@G?Y?Y5JP7Y!7J^YP7?7??7J?7?JYJ7^[email protected]@P~.::^BPP#^JJ.:!JPBP^::Y&#######    //
//    ########P:::^::.GG5..?Y~5::!:::.^J#&B7^~7?JYJJJJJJJJJJYJ??7!~:::J&@5:.::::^::5PB^.!G7GP?J:.Y&#######    //
//    ########P::!G::.JJP:^JG.7P:.:::::.:!5#BJ^..:^^^^^^^^^^^::::::^J##Y~:::::::~:.J&5..^B:!J::::Y&#######    //
//    ########P:.?5.::?.5?~~?Y.P!.:::::::[email protected]&GY!:::::::::::::::!P&@J..:::::::7G:.!7P^~?B7.PJ:::Y&#######    //
//    ########P::!G:!G&G##GG5#7P!::::::::.^[email protected]&[email protected]~:^^^^^^^^^::[email protected]@@@B?^.:::::.YJ.:~!G5YJ~G^?5:::Y&#######    //
//    #######&5:::Y#&#BPPGYG##&J:::::::[email protected]@P7^.^[email protected]^::::::::::[email protected][email protected]&5^.:::.7PJB##B#B#B#PP!:::Y&#######    //
//    #######&5::::JPJ?755!7?5J:::::::[email protected]@P~::::::7GB5?7!!!!7JG#Y~~!~~?#@&7.::::P&P5YYP555##!::::5&#######    //
//    #######&Y::::.~!!JBBY5P~.::::::[email protected]@?::::::::::^7JY5555YJ7^^[email protected]@7.::::7J?7?B7?JJ~:::^:Y&#######    //
//    #######&Y:::^7BJ7JP#PJ#J.!~:::[email protected]@?.::^^^:::::::::::::::^~!Y5YYYY~^[email protected]&^:::~^:!P#&BJYJ.::^^:Y&#######    //
//    #########~:!5PYGB^P~~5#5?#7.:::#@G::!~::^^^:^:::::::::^^[email protected]@5.::PYPG!55?BGG!7~:::5&#######    //
//    #########~::::::B~P~. YJ~P^::[email protected]@?::^57~::^~::::::::::^[email protected]#:::^!^B~5?.JG75#!::^B########    //
//    #########7::::.YY.?G!^~P~!5.:[email protected]&^::[email protected]@?:::77~^:::::::^[email protected]@[email protected]@7.:P7:G:P!7?5G~!J::^B########    //
//    ########&J:::~Y&GBB##BBB#?P..^&@G:^:[email protected]#^::::^[email protected]@[email protected]@5.~G.5GY#G5Y?G?7G::!#########    //
//    #########5:::^B&GG5PP5GB&#~:[email protected]@Y~~~&@5::^^^::::^^^^~!7?JJY5PG#@@&P55&@#:^BP&&GGGP#&&&G!::5&########    //
//    #########G::::~5J?7BY!7Y5~::[email protected]@J!^[email protected]@7:^^^^^^^^^~~!7?JY5PPPGG#&@@GPP#@@!.?&PYJPGJJYGG~:::P&########    //
//    #########&?.::::~7?BPBBY:.::[email protected]#!!^[email protected]&^:^^^^^^~~~!7?JYY5PPPGGGB&@@[email protected]@J..^7??5BJ5G5:::::P#########    //
//    ##########5!J^:YB5YBBBGGJJ~^~&@G~~~#@B::^^^^^^~~!!7?JYY55PPPGGG#@@#[email protected]@P::7JJ?Y#B#5BJ!!:^G#########    //
//    ###########B&GP#&#B###GPG#BBB##BGGG###PGGGGGGGGGGGGGGBBBBBBBBB#####BB####GG##&B###BGG#&#GB##########    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SLAYR is ERC721Creator {
    constructor() ERC721Creator("BabySlayr", "SLAYR") {}
}