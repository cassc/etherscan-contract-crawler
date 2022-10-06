// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bank of Pepe
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#######&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###########&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#####################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###############################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&#######################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&##########################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&##########################################&&&####BBGGB#&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&##########################################BBBGGGGGGPPGPPB&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&###################################BBBGGGPGGGGGGGGY??YPGP#&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&#############################BBBGGGGGPPGGGGGGGGGGG?7777JGPG&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&########################BBBGGGGGGGGGPPPPPGGGGGGGGGG5YYY5YGGPB&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&##################BBBBGGGGGGGGGGGGGGPPPPP5PGGGGGGGGGGGGGGGGGGP#&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&#############BBBGGGGGGGGGGGGGGGGGGGGGGPPPPPGGGGGGGGGGGGGGPPPPPPG&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&#####BBBGGGGGGGGGGGGPPPPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPGPB&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&###BBBGGGGGGGGBBBBBBGGGPYYPPPGGGGGGGGGGGGGGGPPPPGGGGGGGGGGPPPPPGGGP#&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&###BBBGGGGGGGBGGGGGPBGPGPYPJYJJYPGGGGGGGGGGGGGGGGPPPPPPGGGGGGGGGGGGGGGGGGG#&&&&&&&&&&&&&    //
//    &&&&&&&&#BBGGGGGGGBBBGBBBGP55YJ5G5?Y5Y5PGPGBGGPPPPPPPPGGGGGGPP55PPGGGGGGGGGGGGGGPGPPGPG&&&&&&&&&&&&&    //
//    &&&&&&&BGGGGGGGGGG55PBPY5J5YJPJY5PYYGBGGPPGBGPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGPPPPPPGPB&&&&&&&&&&&&    //
//    &&&&&&&BGGGPPPPPGJ???PGJ55JY5PPPPGGBBPPPGGGBGPPPPPPGGPPPPGPGGGGGGGGGGGGGGGGGGGGPP55PPGGG#&&&&&&&&&&&    //
//    &&&&&&&#BBGGPPGGBP???JPGPGGGGGGGGGGBGGGGGGBGPPGGGGBBGPPPPPPPPGGGPPPPPGGGGGGGGGGGGGGGGGGPG#&&&&&&&&&&    //
//    &&&&&&&&BGBGBBBBBG55PGGGBBGBGPPPPPGBGGGBBBBJ??P##BBGPPPPPPPPPPPGP55PPGGGGGGGGGGGGGGGGGGGPB&&&&&&&&&&    //
//    &&&&&&&&#BBGGGGGGGGBBBBBBBBGGGGPGGGYJJJB##BGPPGGGPPP5PPPPPPPPPPGGGGGGGGGGGGGGGGGGGPPPPPPGG#&&&&&&&&&    //
//    &&&&&&####BBGGPPPPPGBGP5YJ?7!?BBBBGPPPGGGGGPPPPPPPP5PPPPPPPPPPPGBGGGGGGGGPYJ???JY5PP55PPGGG#&&&&&&&&    //
//    &&&#######BBGGPPPPGJ!~^^^~~~~^YBGGGGGGBPPGPPPPPPPPPPPPPPGGGPPPPGGGPPPPPPJ7??Y55YJ??5GGGGGGGB#&&&&&&&    //
//    &&&&&&#####BBGGGGGBJ:^^~~~~~~^~5PPPPPGGPPPPPPPGGGGPPGPPPPPPPGGGGPPPP55PPYY5PPGPPGB57PGGGGGGGB&&&&&&&    //
//    &&&&&&&#####BBGGGGGG7^^^~~~~!7?PGPPPPGGGPPPPGPPPPPPPPPPPPGGGGGPP5PP5P555P555GG5555PYYGPPPPGGG#&&&&&&    //
//    &&&&&&&&&####BBGGPGGP7!?JY5PGGBGGGGGGGGBGGGGGGPPPPPPPPPPGGGGGGPPGPYGG555Y5PP55P5555Y5PPPPPPGG#&&&&&&    //
//    &&&&&&&&&&&&#BBGPPPPPGGBBBGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPGGGGGGPPP5555P555PP55YYYYYYPGPPPGGBB#&&&&&&&    //
//    &&&&&&&&&&&&&#BBGGGGGGGGGGGGGGGGGGGPPPPPPGGGGGGGGGGGGGGGGGGGGGGPP55555Y5PP555YYY5PGGBBB###&&&&&&&&&&    //
//    &&&&&&&&&&&&&&#BBGGGGGGGGGGGGGGGGGPP55PPGGGGGGGGGGGGGGGGGGGGGGGGGPP5PPPPPPPGGGBB####&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&BBGGPPPGPPGGGGGGGGGGGGGGGGGGGGGGPPGGGGPPPPPPGGGGGGGGGGGGGBB####&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&#BBGPP5PPPGGGGGGGGGGGGGGGG55G5YG55GGGGPP55PPGGGGGGBBB#####&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&#BGGPPGGGGGGGGGGPPG5PGYPG55GGGGGGGGGGGGGGGBBB###########&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&#BGGGGGGGG5PGYGP5GPPPP5PPPGGGGGGGGBB#####################&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&BBGGPPPPPYGGPGGGGGGGPPPGGBB###&&&&&&&&&&################&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&#BGGPPPPPGGGGGGGGGBB##&&@@@@@@@&&&&&&##############&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&#BGPPPPGGGGBB##&&@@@@&&&&&&###################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&##BBBB###&&&&&&##############################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#############################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#######################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&########&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&####&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BOP is ERC1155Creator {
    constructor() ERC1155Creator() {}
}