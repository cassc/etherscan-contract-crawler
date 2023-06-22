// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Late Night Cigarettes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    PPPPPPPPPPPPPPPPPPPPPPPPP?~~~JJ:.:::~7~~~!5&BJ~:::^G##^:::5BGP7^^~77Y&&&P5Y5PB###BY~:.JGPJY55?~~~~!~    //
//    PPPPPPPPPPPPPPPPPPPPPPPY!~~~Y5GP?^.::^!!~~~5##B?^::?&?.::?#&#G5?^:^!~Y5GGJ!^:7G&##G7!~5B#PP55?~~~~~~    //
//    PPPPPPPPPPPPPPPPPPPPPP?~~~!~Y555GB?:..:~?YGGPG&#5J5B#~.:!B&B7^:^JJ~^:.7YY:.:~?PG#G777Y#&BJY7!~~~~~~7    //
//    PPPPPPPPPPPPPPPPPPPPP7~~~~!~~!YP5PBBY~7??77YPP#&#BGYY?!:~!7~:^~Y?^::!JPG5?YG##&#5^:~5B5?~:!J!~~~~~~!    //
//    PPPPPPPPPPPPPPPPPPPG?~~~~~~~~~~!J55PG#G?7~.:~5B#&5~~?P!!7~!!!7GJ:~YGBBB##&@@&###B555?^..~7PBPY7~~~~~    //
//    PPPPPPPPPPPPPPPPPPG5~~~~~~~~~~~~^~?5P#&#P?7~::P&@P^PG#BBBB#B!:YBG###BBB&@@@@&BB##B!..:~JB&@#GPJ~~~~~    //
//    PPPPPPPPPPPPPPPPPPB!~777!~!~~!7!77!~B##&@&J^:.^#@@Y:JB##BB#7:JP#@&#BG5:7#7~!JJYGGG57JP###&#G?7~~~~~~    //
//    PPPPPPPPPPPPPPPPPBP^!7!57J7????J~!JY&#&#@@&[email protected]@5!5GB#@@&J5PYY55PGPGPY#Y!7J7?JJB####Y~:?!Y::::::::    //
//    PPPPPPPPPPPPPPPPB&[email protected]@@&B#@@P::~!Y&@@@B?^~::::?&@@@@@#!!??JY#GPJ7775##BBPYYYY55    //
//    PPPPPPPPPPPPPPG###77?~~?!7~777~?~^:..:~57#@B7^5G!:.:^Y&&@@@@5~GGGPYJ?5##&B^:~PBBP!:~?JJJ&&#57G#BBBGB    //
//    PPPPPPPPPPPPPG####?^7~7P75!55!:..:^!YBB57YGP?J~.:^^[email protected]@&G#&&&#@@@@#5J!7JPG!~JGB#J~^!Y5YJ7~:..:!BPPGGG    //
//    PPPPPPPPPPPPP#####J~!7?7!!!??!~7JPG&@G!~7?YY5G:^^Y&@&@#BBGBB#&&G!:~~~::^^7!!Y?!^^!7!~^::^~?YPGGYJY55    //
//    PPPPPPPPPPPP######5~!~~!~~~!!7JY??!P&BBB57??7?7?#@#77?^^^^~!7J5??5G5P?YYP7~YYJ~::.^!??JG#&@&BGPY^~~~    //
//    PPPPPPPPPPPG&#####G!~~~~~~~~!?JY55PB##&@@GJ~~^[email protected]@@#?JY?!!!!7!7J~55J::::^7?JYG##[email protected]@@&Y???7~~~~    //
//    PPPPPPPPPPPB######B!~!7JY5PPGGGBB######&@@#!::[email protected]@GP55GBB#?7??J~:??5?~^::^[email protected]@@@@&GP#@@@&!~~~~~~~~~    //
//    PPPPPPPPPPPB####&&#J55YJ?YPB#####&######&@@P:^[email protected]#~..:^7YB#J~~!!~7G&@@&BPY7??#@@B7JB#&@@@@G~~~~~~~~~~    //
//    PPPPPPPPPPP###BPYP?~^:::.:JG#####B55YJJP&@@&7~?PB5YJJ??5J7?^:G&@@@&&&&###PG#&BGB?~!::!PB5?~~~~~!~~~~    //
//    PPPPPPPPPPP###5?~::^:[email protected]@G7~~PJPG!::^J~..Y#&BY7::~5GG&&GJ^~YYBB7:...:~7!~~~~!~~~~    //
//    PPPPPPPPPPPG##BJJ5PGBBP5?7!!7J!J577Y~~?~~~?B#B5P5~7P?77^[email protected]?7!:!G&@B??757!!P&#G?~!^:!?7~~~~~~~!    //
//    PPPPPPPPPPPP#####&&&&#Y!!?777?J!?5!77~?!~~^^!JGGGBPJ7J55BBBB&@@[email protected]@@&BY57YB&BGYJ5GGBB!~7??!~~~~~7?    //
//    PPPPPPPPPG###########&#P!7777??7!Y7~7!7!~~~~~~~!7!:..^GB#BB#@@@@@@#557:.:Y&BP5P7^^~?5PGGJY?!~~~~~7!:    //
//    PPPPPPPPPB############&&G7!~~~~!!~~~~~~!~~~~~!J~:..:!PBPJ55YPPGGB#?J7!?J5BP7!!7~~~~~!YPP5J~~~~~~!~..    //
//    PPPPPPPPPPGGGG##########&BY!~~~~~~~~~~~~~~~~!?!:.^!5B#Y?J??7~^^^^!YY?J#&#BP?!~~~~~~~~~!7~~~~~~~~:.:~    //
//    PPPPPPPPPPPPPPG##########&&BJ!~~~~~~~~~~~~~~!JJ7?PBBGY!Y?!77~~~~~~~7P&BPP577~~~~~~~~~~~~~~~~~~^:^7YP    //
//    PPPPPPPPPPPPPPPPB##########&&BY7!!!~~!~~~~~!Y7!?GP55P!J5!77~~~!~~~~77BP5P7~~!~~~~~!~~~~~~~~~^:^75PPP    //
//    PPPPPPPPPPPPPPPPPPB##########&#BPJ!~~~~~~~~J?JJ?JJ?5J!?7P!7~~~~~~~~775P5Y~!^!~~~~~!!~~~~^^^~?5PPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPGB##########&#G57!~~~~?7~7J7^??5~!!7J!J~~~~~~~~~7!5P7~~~^!!~~~~~^^^~7YGBBGPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPGB###########&#B5J7!??J?J777J77?7?777~~~~~~~~~!!?P!~~~.~~^^^~!?5GB##BPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPBB###########&##GPY?77??!J??~~!!~~~~~~~~~~~^~~7~~!^:^!?5G##&##BGPPPPPPPPGPP    //
//    PPPPPPPGBBBB#########BBBBBBB##################BGGP55YJ?7!!!!!!~!!!!!!7!7!!!!YB#&&###BBGPPPPPPPPPGPPP    //
//    BBB###########################################################BBBB#####BBB##&####BGGPPPPPPPPPPPPGPPP    //
//    &##BGBB###BBBBBBB#########################################################BBBGGGPPPPPPPPPPPPPPPPGPPP    //
//    57!!!7!7!!!!!!~~~~~!!!7?JY5PPGBB#&###############BBBBBBBB########BBBBGPPPPPPPPPPPGGGPPPPPPPPPPPPGPPP    //
//    ::!~~!!~^~~~~~~~~~~~!!~~77J77?77?J5GB#&###########BBBPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGPPP    //
//    :~!~~5Y!7~~~~~7~~~~Y777?J?J7?7??J??!!?YG##&###########GPPPPPPPPPPPPPPPPPPPPPGGPPPPPPPPPPPPPPPPPPGPPP    //
//    ~^!~!5P?7!~~~~~~~~?J57!!7PJJ~!J?!!J~~~~!7JP#&&##########BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    !~7^?5PG7?~?~~~~~~!75Y7JYP?JJ?JJ?J7~~~~~~~!?5B#&&#########BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    ~!!~5PP#JJ~!~~!~~~!J~J5!P5PPGP77J?^~!~~!~~~!!!JP&&##########BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    7?!YPPB&B?~~~~~~~7?!?Y7?GGBGJ?YJ7~~~~~~~~~~~~~~!7P#&##########BPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    ?!5G#&#Y?Y5J^^~^^!7???JBBG?^::~77~~~~~~~~~~~~~~!!!?G&##########BGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    !!YB5J?!!?7B#BGGGPYPJ5BG?~:.:^J7!~~~~!~~~~~~!7!~~~!!5#&&############PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    5B#G^.:[email protected]@@@@@&BB##G7:^:!77~^~~~~~!777!!577??77??7J#&&##########BPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    #B?JYG&@@@#JY5&@@BBB#P5Y??PGGGB57~^~!~?!~?!Y5!?J777?7!?B&&&&#B###GPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    [email protected]&B7:[email protected]#Y7J5!~?J5J^?P5G##Y!~~7!^JJ!Y57??!!7?YPGBPP5Y?P##BPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    ^7P#&#GP7^:!YP&&G^.^7!:^!PBYP?~7P&@&Y!J~~7YJ7YP5PPBPYJ?7~^::^?Y###PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    &&BG###&&&&@@@&#~:[email protected]@@GYJY55G#&&&#BY~:::^~~7P55B###GPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    @J?JY5B&@@&B?~~7^!7B#57~:..^[email protected]?::?&@@#####&&#####BG5??YPPJB&&#####PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LNC is ERC721Creator {
    constructor() ERC721Creator("Late Night Cigarettes", "LNC") {}
}