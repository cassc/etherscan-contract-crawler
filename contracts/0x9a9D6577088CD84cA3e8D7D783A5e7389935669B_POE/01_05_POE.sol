// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Permutations of Ego
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    ~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~!!!!!!!!!!77777    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~!!!!!!!!777    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~!!!!!!!!777    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:^~!?JJJJJJJY555YJJ7!~^^~~~~~~~!!!!!!!!7    //
//    ^^^^^^^^^^^^^^^^:::::::::::::::::::~Y#@GPY???77???YYYY55P5J7~~~~~~~~!!!!!!!    //
//    ^^^^^^^^^^^::::::::::::::::::::::::?5B&##BPPPPPY?!777~^~G&&&B5?~~~~~~!!!!!!    //
//    ^^^^^^^^^::::::::::::::::::::::::::Y#[email protected]@BGGGGPY??7!!!5&&&@&&#GJ!~~~~!!!!!    //
//    ^^^^^^^::::::::::::::::::::::::::::7&[email protected]!5&&&#&&&&&#GY!~~~!!!!    //
//    ^^^^^^::::::::::::::::::::::::::::::PB5Y77Y&&BGP555YJ5###&&&&##&&&#GJ~~!!!!    //
//    ^^^^^::::::::::^7?7^::::::::::::::::!#GPJ77J#@#####BB###########&@@&#5!~!!!    //
//    ^^^^^:::::::~7YG&@&BJ::::::::::::::::J&PYY5PG&&P#&&&##&&&#&&BBBB#&@@&#5!!!!    //
//    ^^^^^:::::~?P#@@@@@##G!::::^Y?Y?::::::5GYPGGB#&#YB##BB##B##GGB#BB#&@&&#Y!!!    //
//    ^^^^::::~JP#@@@@@@@@P557:::~GPGJ::~^::^GG5PGP#@@#PBGPJJJY5B###&#B#&&@&&B7!!    //
//    ^^^^^:^JP&@@@@@@@@@@&GP5?::::~^:::^::::~GYPB#&&@&&#PJ?77?YPB&@@@&&&&&&&#5~!    //
//    ^^^^:!PB&@@@&#BGB###&&&BPJ^::::::::::::.~GP#@@@@BG&#PJ??J5PB#&@@&&&&@@&&#!~    //
//    ^^^^~PB&&&@&BGBBBBBB#&&&&G5~.::::::::::!:!GPPBPBPYJ&&G5Y5PPGB#&@@@@&&@@@&7~    //
//    ^^^~PB#&&#&#BGB#####BPY5GP##!.:::::::::^7^!JGPPG5YY5&&BGPGGBB#&@&&&&@@@@&7!    //
//    ~~^YB#&&##G55GGBGGPY!^:^!75&&7::::::::^:^!!^Y5P5555YG&##BBBB#&&&&###&@@@G!!    //
//    ~~!GB&&&#BPPGBBBBBB?^^::^7JP##?:~7!!!!!5?^?Y5YGY55PPGB&&#BB#&&@&&#&&&&&#J!!    //
//    !~JB#&&##GGB#BGB&&@&Y!!?5BBB#BB?:^^^^?J5GJ5&7~BB?Y5PGG#&#&&&&@@@&&&@@&&P7!7    //
//    !!Y##&&&#BBGPPGB&@@&#GGB&@@&&&##J^~755!!JP5Y~^~5J7!!?YP#&#&&@@@@&@@@@&B?777    //
//    7!Y&&&&&&#&##GPPB###&#B#@@@&&&@#&J??~7Y5J~!~~~~!Y5?7~!7?&@&@@@@@@@@@&BJ7???    //
//    ?7Y&&&&&&@@@&#BGBGGBB#B#&&&@&#&&B#[email protected]@@@@@@@@@&GJ?????    //
//    ???G#&@@@@@@&&&&BPGBBBB&&BB&@&&@&PBY!7JJ?777B&BBGB5GBP55G&@@@@@@@&#5??JJJJJ    //
//    JJ?5#&@@@&@@&&&&#BBBB#&@#GG#&@&#&5JPY77777?7JGBG5J??5#[email protected]@@@@&#PJJJJJJJJY    //
//    JJJJP&&@@@@@@&&&&&#B&@@&BGG55GBGGPPB#J????????JJJ????JG##B&@&#G5JJJJJYYYYYY    //
//    YYYJJG&@@@@&#&&&&&&@@&&@&G5YJYPGPG#@&#JJJJJJJJJJJJJJJJJY5PBBPYJJYYYYYYYYYYY    //
//    YYYYYYP&@@@@&#&&&@@@@@@@&&#G55PBGB##&@BJJJJJJJJJJJJJJYYJJYJJJYYYYYYYYYYY555    //
//    YYYYYYY5B&@@@@&&&&@@@@&&&@@&#BBB#&&@@@@GJJJJJYYYYYYYYYYYYYYYYYYYYYYYYY55555    //
//    YYYYYYYYY5B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@5JJYYYYYYYYYYYYYYYYYYYYYYYYYYY55555    //
//    YYYYYYYYYJJ5G&@@@@@@@@@@@@@@@@@@@@@@@@@@BJJJJJYYYYYYYYYYYYYYYYYYYYYYYYY5555    //
//    YYYYYYYYJJJJJY5G#&@@@@@@@@@@@@@@@@@@@@@@BJJJJJJJJJYYYYYYYYYYYYYYYYYYYYYYYY5    //
//    JJJJJJJJJJJJJJJJJY5PB#&&@@@@@@@@@@&&#BG5JJJJJJJJJJJJJJJJJJJJJYYYYYYYYYYYYYY    //
//    GGGGGGGGGGGGGGGGBGGGGBBB###&&&&&###BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB###    //
//    #######################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    #######################################################################&&&&    //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract POE is ERC1155Creator {
    constructor() ERC1155Creator("Permutations of Ego", "POE") {}
}