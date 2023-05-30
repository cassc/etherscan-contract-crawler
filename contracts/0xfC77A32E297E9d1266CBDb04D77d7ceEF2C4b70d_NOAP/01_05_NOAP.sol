// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Night Owls Curated
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                               ..?JJJJJJJJ:.                                                //
//                                 5P~.     :!PG#&&&#&&&&&#&&&#GG7~^    .~5G                                  //
//                          ?&#Y7.:&@@&#YJP&&&&&#B##BBBBBBB##B##&&@@GJY#&&@@:~YJB&P                           //
//                          ^&&#&###BB#&&#BGB#######BB###BB########GG#&&#BBB#&&##&7                           //
//                           ^&&#B#BBGPGGBBGPPBBB#BB###B###BB##BBGPGBBGGPGBB#BB#&!                            //
//                            .Y#&####BBGGGB#BPPPBB###BBBB##BBPPPG#BGGGBBB###&&P:                             //
//                              .~B&&&####BB###BPPG##BBBBB##BGPB###BB####&&&&5:                               //
//                               .BP55GBB####BB##BB####B###BBB##BB####BBG555B^                                //
//                               YB???5G#&@@@@&#GG#####B#####GG#&&@@@&&GP???PG                                //
//                              ^#J?J&@P.^@@@@@@&BPGGBBBBBBGGB&G?^@@@@@#@&Y?JB7                               //
//                              !#??5&J:P#@@@@@#!&#BGPB#BGGB#&[email protected]@@@@!7&G??BY                               //
//                              !#???PP^[email protected]@@@B&J^B5JG&@@@@BJJ#~7&@@@&#P^YG???BY                               //
//                              :B5???YPJJJJJ?JJPJ?5&&&&&@@P?J5YJJJJ?JJ5Y???JB~                               //
//                               [email protected]&&&&@@P???JY5555YY????YB^                                //
//                                .?PY?????????JJY55B&@@@&B55YJJ?????????YPJ.                                 //
//                                   J#P5555Y55PGPPPPPB#BGPPPPGP55Y5555P#5.                                   //
//                                  .Y#GGB##BBBBBGGGGGP5PPGGGGGBBBB##BGGBP.                                   //
//                              .^JP##GGBG5YJJJJJY5GBBBBBBBGP5JJJJJY5GBGGG#GY^.                               //
//                            .JBGGBGB#BY???????????J5GBBPJJ??????????YG#GG####Y.                             //
//                          .YBGBBBPP#BJ???????????????Y????????????????G#GPGGBGBP:                           //
//                        :YGBGGB#BG##???????????????????????????????????B#PPGPGGBG5^                         //
//                       ~&#PGPG#B#&#Y???????????????????????????????????Y#BPPPGBBG#&?                        //
//                      7#BGGPPPGB#&#?????????????????????????????????????B##GGGBB###&J                       //
//                      J&BGGPGPPPP##?????????????????????????????????????B#GPPPGGGBB&5                       //
//                      5#GBPPPGBBB##J??????????JJ???????????JJ???????????B#BGGPPPGGGBB                       //
//                      [email protected]##GPB&G?JJJ????JJJJJJ???????JJJJJJ????JJJ?P&#GPGBGPGP&5.                       //
//                       .&&&&###GB##&PJJJJJJJJJJJJJJJJ??JJJJJJJJJJJJJJJ5&##BGB#B#BB&.                        //
//                        :?#&B#&#BBB#&PJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ5&&BBBB#&#&&?:                         //
//                          [email protected]#&&#BGB#&#5JJYYYYJJJJJJJJYJJJJJJJJYYYYJJY#&&BGG#&&#&P                           //
//                           5&&&@&BB#&##PYYYYYYYJJJJYYYYYJJJJYYYYYYY5###&[email protected]&&&G                            //
//                            :5?7####&#B##5YYY5YYYYY55Y55YYYYYY5YY5B###&&##BJ75^                             //
//                                 !~ ?&#B#&BGP55JYYYYJYYYYYYJY5PPB&#BB&Y ^!                                  //
//                                     7&#&G555GBBPPPPPPPPPGPBBGP55G##&J                                      //
//                                      !&[email protected][email protected]?7?5G&?                                       //
//                                       &#@[email protected]#&^         .&#@[email protected]&&.                                       //
//                                       !&GPGB#@&###########&@#BGG5&?                                        //
//                                           7B&BGGBBGB#BGBBGGG&B?.                                           //
//                                           ^&BGB#GPGBBBGGG#BGG&7                                            //
//                                           B&##&5&#GGBGGB&5&####                                            //
//                                            ^55! P##BGB##G.^55!                                             //
//                                                  :!5BP7:                                                   //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NOAP is ERC1155Creator {
    constructor() ERC1155Creator("Night Owls Curated", "NOAP") {}
}