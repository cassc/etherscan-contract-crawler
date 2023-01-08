// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xLATCH
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@G5PGGGBBB#####BBBGBBB#####&###&&&#&#BBBBBBGPG5?&@@@@@@@@@@@@@    //
//    @@@@@@@@P:YJ?7!!~~~7!???JYYYYJJYY5Y5YYPP5PY5P5555555J?! [email protected]@@@@@@@@@@@@    //
//    @@@@@@@@G.&@@@@@@@@&&&&&@@@@@@&&&@&&&&&&&&&#&#####&&B#P [email protected]@@@@@@@@@@@@    //
//    @@@@@@@@B.#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@# [email protected]@@@@@@@@@@@@    //
//    @@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:[email protected]@@@@@@@@@@@@    //
//    @@@@@@@@# [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^[email protected]@@@@@@@@@@@@    //
//    @@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@    //
//    @@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5.&@@@@@@@@@@@@    //
//    @@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@    //
//    @@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@    //
//    @@@@@@@@@:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^[email protected]@@@@@@@@@@@    //
//    @@@@@@@@&:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&!^@@@@@@@@@@@@    //
//    @@@@@@@@@~YBPGGGGGGGPPGP555YYJ?J???JJY5?J?7????J7?JJ?JJ7^^#@@@@@@@@@@@    //
//    @@@@@@@@@#G555555YYYYY5YYYJJJYYYY55PGGBGGPGBG#&@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@B########&&&&&&&&#[email protected]@@@@@@@@@@@    //
//    @@@@@@@@77?JJJYYYY5555555555PPGGGGGBB#B#####&[email protected]@@@@@@@@@@@    //
//    @@@@@@@G:#@@@@@G7~JGB&@@@@@@@@@@@@@@@@@@@@@@B7? ^?7. ~?&P.#@@@@@@@@@@@    //
//    @@@@@@@[email protected]@@@@7 :!...:[email protected]@@@@@@@@@@@@@@@@@@@[email protected]@@#Y^ .G:[email protected]@@@@@@@@@@    //
//    @@@@@@#:[email protected]@@@# .&@&&#G^ [email protected]@@@@@@@@@@@@@@@@@&!^ [email protected]@@@@&7 ~J^&@@@@@@@@@@    //
//    @@@@@@[email protected]@@[email protected]@@@@7 [email protected]@@@@@@@@@@@@@@@@@@7::&@@@@@@@!:#[email protected]@@@@@@@@@    //
//    @@@@@@?.BG [email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@P. [email protected]@@@@@@^[email protected] #@@@@@@@@@    //
//    @@@@@@[email protected]@7^###@@&BB#&@@@@@@@@@@@@@@@@@@@@@@@5. :[email protected]@&?.#@#[email protected]@@@@@@@@    //
//    @@@@@#.~Y7~ :!!J#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G~   ~~:^[email protected]@@J [email protected]@@@@@@@    //
//    @@@@@B.5BGB?.&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@#[email protected]@@@@@@@    //
//    @@@@@?:@@@@@[email protected]@@@@@@@@PGBB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@    //
//    @@@@[email protected]@@@@#[email protected]@@@@@#Y:Y5^!555~5PPPJ!GGGBGP&@@@@@@@@@@@@@@@#[email protected]@@@@@@    //
//    @@@@[email protected]@@@@@@@@@@@@@@G.P#75&&P G&&&~ GGPP! ^JPPG&@@@@@@@@@@@J [email protected]@@@@@    //
//    @@@@7:&@@@@@@@@@@@@@@@&P##55GG5^YGPP!:PPPP?  YYYB&@@@@@@@@@@@#[email protected]@@@@@    //
//    @@@&^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@&@@@@&[email protected]@@@@@@@@@@@@@@@@Y.GGG&@@    //
//    @@@P YBB#######&BB######&#&&&&#############&&########B######&&#..  [email protected]    //
//    @@@GJJ?7!~^^~!7???J?J?????7777!~^!^^~~~!77^~!^~~77!!^~~!!7!????: [email protected]    //
//    @@@@@@@@@@&####BBBBBBBBBBB#####################B####BBBGGGPPPGP?:[email protected]@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@    //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract OxL is ERC1155Creator {
    constructor() ERC1155Creator("0xLATCH", "OxL") {}
}