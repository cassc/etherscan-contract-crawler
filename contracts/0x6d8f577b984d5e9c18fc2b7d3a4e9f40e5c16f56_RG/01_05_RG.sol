// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Retro Grade
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    @@#GG&@&G##BBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB#&#GGGGGGGGGGGGGB&@@&&@@&GG&@@    //
//    @@BPPB&@@@@@@@&GGGPPPPPPPPPPPPPPPPPPPPPGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGBGPPPPPGGGPPPPPG&@@@@@@GPG&@@    //
//    @@#&&#&@@@@@@&GPPPGB#&&#GPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55PPPP#&&@@@&BGPP#@@@@@@&&&@@@    //
//    @@&&@@@@@@@@@#GG#&@@@&&&#55555555555555555555555555555555555555555555555555PGPPGB&@@@&#&&@@@@@@@&@@@    //
//    @@@@@@@@@@@@@@@@@@&#G555555555555555555555555555555555555555555555555555555YYY55PG#&@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@&&#BGP5YY555555555YYYYY5YY555555YYYYYYYYYYYYYYYYYYYYYY5G#&&@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]_U_C_ME 2023YYYYYY5#&@@@&&&@@@@@@@@@@@@@@@@@@@@@             //
//    @@@@@&&@@@@@@&&@&&&#G555PG#&@BYYYYYYYYYYYYYYYYYYYYYJJYYYYYYYYYYYYYYYYYYY#&GGP5YY5GB&@@@@&&@@@@@@@@@@    //
//    @@&@@@@@@@@@@@@@@@@@&&BPYJJYPBYYYYYYYYYYYYYYYYYYJYJP#&#P5YJJYJJYYYYYYYYYYJJJJJ5B#&&@@@@@@@@@@@&@@@@@    //
//    @@@@@&@@@@@@@@@@@&##&@@@&[email protected]@@@@&BPYJJ??!7??JJJJJJJJG&@@@&&#&@@@@@@@@@@&@@@@    //
//    @@@@@@@@@@@@@@@@@@&#5YPB##JJJJJJYJJJJJJJJJJJJJJJY#@@@@@@@@@&&###PJ?7???JJJY&@&&G5P#&@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@BJ?JJJJJJJJPBGYJY55YJJJJJJJJ#@@@@@@@@@@@@@&&##BY77?JJ#&GY?J#@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@&#@@@@[email protected]@@@@@@@@@@@@@@@@&#Y!7??YJ??5&@@@[email protected]@@@@@@@@@@@@@@@    //
//    @@@&&@@@@@@@@@@@@G?P&@@@5????????????????????JYPB&@@@@@@@@@@@@@&&[email protected]@@#[email protected]@@@@@@@@@@&@@@    //
//    @@@[email protected]@@@@@@@@@#G?77JP&@#?????????????????JPB&@@@@@@@@@@@@@@&&#G?!777??????77#@&BJ77?#&@@@@@@@@GY&@@    //
//    @@[email protected]@@@@#@&G7Y#&57J#@@BBG?7??77777????JB&@@@@&@@@@@@@@@@@#J7777?777777?5GB&@#?77YP5?B##@@@@G77#@@    //
//    @@[email protected]@@P7P#P5P#&@&&&&&&#[email protected]@@@&###B#B##&@@@@@5?77777777775#&&@&&&[email protected]@#5Y7?&@@5777#@@    //
//    @@[email protected]@&?B###&@@@@@@@@@&&#[email protected]@@@&BB55Y55PPG&@@@@#Y777777777PB#&@@@@@@@@&&##BJ&@#?777#@@    //
//    @@5!!!7Y&@?JP#&@@@@@@@@@@@@&[email protected]@@@@GBB5#G5P&B5#@@@@@&Y7!!!!7!75#&&&@@@@@@@@&&[email protected]!7!!#@@    //
//    @@[email protected]?5&B&@@@@@@@@@@@@@@&J!!!!!!!75#&@@@B#BBBG5#[email protected]@@@&&G?!!!!!?#@@&&@@@@@@@@@@&&#[email protected]!!!7!#@@    //
//    @@[email protected]#@@@@@@@@@@@@&B#&&?!!??!!7JP&&5#BYP##5~##[email protected]@@GJY!!!!!!!P&5?#@@@@@@@@@@@@#[email protected]?!!7YP&@@    //
//    @@Y!!!!!#@J!7&@@@@@@@@@@@@@7!YB?!J##?!5P&@[email protected]&&&&&&&&#&@&7B&YJ7!!!!!!??~~&@@@@@@@@@@@@@[email protected]!!75G&@@    //
//    @@5!!!!!&@?!!P&&@@&#@&@@@@@GBBG?!!?7!?G&@[email protected]&#&&&&&&#&@#..#BPP?!!!?G###5&@@@@@@@@@@@&[email protected]!!7YG&@@    //
//    @@#GY!!!&@5!!!?G&PG!#&#@@@@@@@@&[email protected]&~...#@&&&&&&&&&@@&[email protected]&GY?!5&@@@@@@@@@@#YP#&#GY!!&@Y!!7YG&@@    //
//    @@#[email protected]@5!Y5Y5PY57#B#@@@@@@@@&@[email protected]:&@@&@&&&&@@&@@#~.~#&B5?#@@@@@@@@@@#J!7?J7!!?Y&@#!~75G&@@    //
//    @@#[email protected]@[email protected]&@@@@@@@@@#&JY&5.....:#&@&&&@@@@@@@@&P...7&&B#&&@@@@@@@@Y!?55P?~J5Y&@G!!!YG&@@    //
//    @@#GY!!Y&@5J5GGGGGGJ&&@@@@@@@@@@#J#@@[email protected]@@@@@@@@@@@@@#:[email protected]&#@@@@@@@@@5YPGG57~JYY&@P!!7YG&@@    //
//    @@#G5!!Y&@P555GGBGGY&#&@@&#&&&&&P5&&[email protected]@@@@@@@@@@@@@#.....:5&&#@#&#[email protected]@@BGGBG57~?YY&@Y7?Y5B&@@    //
//    @@#GY!!Y&@BP55GGGBGY&GY#@BYBJ?G7.!##GGY?~..~&@@@@@@@@@@@@@@#^..:JG##&PG5P55##@BGBBBG7~JY5&@Y!7J5P&@@    //
//    @@&BP?YG&@#BGBBBBGPY&BYY&#557^^..!#&&@&#G~.J&@@@@@@@@@@@@@@Y^?P#&&@@&&BPGGGGG&#GBGBG??YPP&&J!JBBY&@@    //
//    @@&##[email protected]@BBBB&&&BGP&#[email protected]?~~.^J&&@&&&&P^^#@@@@@@&@@@@@@&~?#&@&&&@&&##GGB##@G5GBGPGPPPP&@YP#BBG&@@    //
//    @@#G#&BG&@BPBB&&&&##@&[email protected]#GB5JJ!~JPB#&&#[email protected]@@@@&[email protected]@@@@@G^7B&&&#&&&#B###B#&@BPB###GGP5P&@55P5PG&@@    //
//    @@B55GBB&@BGBGGB###BBP5#@&&&#BBBGPJYJP#&[email protected]@@@@G!&@@@@&?Y#&#G5PGBG##&&&&[email protected]&#&&&GJGPGG&@#BBB##&@@    //
//    @@&#[email protected]@#BGBGB&&&[email protected]##&######BGP5PGB#B5J&@@@@J!&@@@@#B#B5YY5PPBGBB##&&[email protected]&#&&&###&&#&@#B##&#&@@    //
//    @@&#GGPB&@&&#BB#&&&##[email protected]&########BBBGPPGB#&@@@&JJ&@@@@GG5?!?5Y5PB#BBB###[email protected]&####&&&&#&@@@&&&&&@@@    //
//    @@&&&&&B&@&&#B&##&&&[email protected]#&&&&&#####[email protected]@@@@&!:^&@@@&JYJYPGYYYYPGGB####[email protected]&#B##&&&&&&@@@&&&&&@@@    //
//    @@&##&&&@@#GGB&&&@@&&&&&@&GG#####BPY?!~^^[email protected]@@@@G:::[email protected]@@@#~??YJB#G5PPP5PGBGGB&@&BBBBGBB#&&@@&B#BB#@@@    //
//    @@&##&&&@@@BGB#&&&&&&&#####BGPY?!~^^^^[email protected]@@@&Y:^^[email protected]@@B7GBBG#&#BBBBBBBBBGB#&#BGGB#&&&&@@@@&&&##@@@    //
//    @@&&@@@@@@@&##########BG5J?!!~~~~!!!!!!?#@@@[email protected]@@&JJB#&&&&&@@@&&&&BBBGGGGBBBB###&@@@@@@&&&@@@    //
//    @@@@@&&&&&&&&&&&#BP5J?77!777???7777?JJ5&@@#J777777J7&@@@@P?JPB&&&&&&&&&&#BBB############&&&&&&&&&@@@    //
//    @@@&&&&&@@&&BP5J????JJJ?JJJJJJ??JJJJJP&@@[email protected]@@@@5??JYGBBBBB####GG###&&&&&&&&&&&#&&&&&&&&@@@    //
//    @@@@@&&#BG5YJJJJJYYY5YYYYYYYYYYYY5YYB&@&&[email protected]@@@#YYYYYYPBBBBBB####BGB#&&&&&&&&&@&&&&&&&&@@@@    //
//    @@@@@@&[email protected]&&&[email protected]@@@P5555555PB##BBBB####BGG#&&@@&&&@@@@@@@@@@@@@    //
//    @@@@&[email protected]@@&P555555555PY&@@BPPPPPPPPPGB########&&&&#BB#&@@@@@@@@@@@@@@@@    //
//    @@@&BGGGGGGGGGGGGPPPGGGGGGGGGG5YJ??J&@@&P55PPPPPPP5P&@@BBGGPPGGGGGGG#&&&&&&&&&&@&&#BB#@@@@@@@@@@@@@@    //
//    @@@@@&#GGGGGGGGGGGBBP5GBBBBGG#[email protected]@&PJ??JJY5PPG#@&@@&BGGGGGGGGGGBG#&&&&&&&@@@&@@&#BB#&@&B&@@@@@@    //
//    @@@@@&&##BBBBBBB##G5G###&##BG&@@@@@&&@@&BP5YJJ????J&@@@@&#GPGGBBBBB##BP&&&&&&&@@@@@@@@@@&BB&@@@@@@@@    //
//    @@@@@@@&&&#####&#5G&&&&&#BGBBBBB&@@&@@@@@@@&&&#BGGB&@@@@@&&BGY5GPYY5##&&&@@@@@@@@@@@@@@@@@@&@@@@@@@@    //
//    @@@@@@@@@@&&&&&&&&&&&&&#BBBBBBB#&&@&@@&&@@@@@@@@@@@@&&&#BBGP5YJY##G######&&&&&&&&@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@&&&&&&&&&&&######&@@@@@@@@&&&&&&&&&@@@@@@@@&####&&&&&&########&&@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@&&&&&&&&######&&&@@@@@@@@@&&&&&&&@@&@&&@@@@@@@&BB####&&&&@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&####BB#&&@@@@@@@@@@@@&&@@@@@@&###BBB#####&&&&&&@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&#######BBBGGBB##&&&@@@@@@@@@@@@&&######&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@&&&&&&###&&&#BGGGGGGGGGGGGGBB##@@@@@@@@@&###&&&&#&&&&&&&@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&#BGGGGGGGGGGGGGGGG#@@BGBBBGGG#####&&&&&@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&#BBGGGGGGGGGGGGGGG&@&##&&###B####&&&&&&@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&#BGGGGGGGGGGGGGG&@@#B######&&#&&&&@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&[email protected]@@BGG#&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RG is ERC1155Creator {
    constructor() ERC1155Creator("Retro Grade", "RG") {}
}