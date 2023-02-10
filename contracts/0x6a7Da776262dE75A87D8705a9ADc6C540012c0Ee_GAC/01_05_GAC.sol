// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gaCruzing 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//                              :~~77!~:.~~:.^~:                      //
//                            :?PGBB##BPY5P?JP57^                     //
//                          :7PB#&&&#####B#BBG?.^^                    //
//                        .?GB###BBBB########B5J??~.                  //
//                     :!?5BBP5YJJYYY5PGBB#######P?^                  //
//                   ^JPPBB5J????JJJYYYYPPGGG##&&#B5~                 //
//                 .JGBGGGJ??????JJJYYYYY55PGGB&&&#GJ!.               //
//                ^P##GBGJYPPPGGP5YJYYYYY55555P&&&&B7~.               //
//               ^GBBGBP?JJJYY5555YJYY55GBBBGP5G&&&G~^                //
//            :!JBGGGGGJJJYY5GGGG5??JY5PPPPPGBBP#&#B~                 //
//           .YGBBGGGGY???JY55555J?JYYPBBBBGGPPPB&#B~                 //
//           ^[email protected]&&?                 //
//           ^[email protected]##B~.               //
//           :YPGGGBPJ??YPP5Y55PPJY5PG55P5YYYYY5#&[email protected]#P.              //
//           .!?J5BB5JJJGBGPPGBBBP5PB&BGPPP5555P&#G#&&B:              //
//               :7!7JYYBBGGPJ???Y55GB#####GPP5G&&&&&@G               //
//                  .?YYGPYYYJ???5Y?YYG###&BPPG#@@@@@@7               //
//                   ^Y5PPYJ?JJY5PPPPPPPGB#GGGP#&B5PGJ                //
//                    !5P5YYJY5PPPPPPPPPG#BBBY::^.                    //
//                    :JPPPPPPGGGBBGPPGGBB##J                         //
//                    .7YPGGBGP55PGBGGGB###5                          //
//                   :~!?PGBBBBGGB####&##BBY                          //
//                  :J7!7?5GB#####&&&&#BGGG~                          //
//                  .?!!77?JYPGBBBBBBGGGGP~                           //
//                   ^?777??JJY5PPPGPPPY7:                            //
//                    .~!7?JJYY55YJ?!^.                               //
//                       .::::::.                                     //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract GAC is ERC721Creator {
    constructor() ERC721Creator("gaCruzing 1/1s", "GAC") {}
}