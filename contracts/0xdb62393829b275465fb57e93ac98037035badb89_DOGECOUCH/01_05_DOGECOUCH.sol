// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Doge Couch
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//              doge couch doge couch doge couch                                                                                  //
//                                                                                                                                //
//                                                                                                                                //
//                         .?~~:.....::::~7~  J&#Y.        .7:        .                                                           //
//                          !PGGGBBGBBBBGGY..#@@@@@BGGG?  [email protected]&P^           ..     :.                                    //
//               ..::^!7JYPGPY55PPPPPPPP5J!7#&&###&@@&&B7:J55P5YY??Y&@&@@@&J!!!:   !PJJ^ .5&@@B:                                  //
//             :G&&@@@@@@@@@@P5PGGGGGGGPP?^G&##BB#&&&#GP?!!!!?YPPYJB&#B#B#&&#BBP::~YGYY5?#####&&G!:                               //
//             GBB#&@@@@@&@&&P?5PGPGPGPG5^?#BBGBB&&#GGP7~J5P55J!^:5BBBGPPB#&#B5!Y?~^~~7?YJ7J5GG5YP#P^::...                        //
//             5PGGB#&&&&&#BP7J5P5P5555YY~P#####B#BB#B?~7!!7?J?!~7GGPPPPGB##G?:^7JY??7!~^!JG&&&#BPG#&@@@@&&&&&##GJ~.              //
//             .J55PPGPP55Y??Y55YYJYY55P5?YGBBGPB##&@#~^?Y5G5Y7!:5PP55PPB#B57:7!~~~^!??~~?PB###BPPGBB&&&@@@@@@@@@@@@P.            //
//             ^5P5555PGB#&&&&&&&&&&@@@@@&#BGGB#@@@@B!..:^~JYYYJ:5GGGGGGGG5?^:7?Y5J!!~^:75PPBBB#&&@@@@@@@@@@@@@@@@&&@G            //
//             J#B####&&&&@@@@@@@@@@@@@@@@@@&###&@@#BB##BP5YPGP~:75PPP5YP55?77~~~!~!7~^7YYYPG##&&&&@@@@@@@@@&&&&&###B?            //
//             !GGBBBBBBBBBBB#####&&&&&@@@@@@@@@@@@@@@@@@@@@&&&&&#GPPPP#@@@P!YJ5YPJ?:.^^^?JPGGGGBB##&@@@&&&&&###BGP?:             //
//             ^GPGGGGGGGGGGBBBBBBGGBPGBB#####&&&&&@@@@@@@@@@@@@@@@&&B5B&@&~.!7YJ?!^. .^75Y55PPPPGGB##&&###BBGP5J?!^:             //
//             :GPPPPPPPPPPGGGGGGGGGBPPGGGBBBBBBBBBBB#####&&&&&&@@&@@&&&&@&#BPPBP??JJYJY5Y?JY55555PPGB##GP5YJ??J5G#&&.            //
//              ~7?JY55PPPPPPPPPPPGGBGPPGGGGGGGGGGGBGBBBBBBBBBBB#BP##&&&&&&@@@&&&@&&&&#BPY7!?JYYY555PGPYJ???YPB#####B.            //
//                    .:^~!?JY55PPPGBGPPPPPPPPPPGGGGGGGGGGGGGGGGBPYPGBBBBBBBB####&&&&&&&&#BPJ7????JJJ???JPG#######BBG             //
//                             .:^~7JYJ555PPPPPPPPPPPPPPPPGGGGGGBPYPPGGGGBBBBBBBBBBBBBBBB#####BBBGGBBB#######BBBBBBB5             //
//                                      .:^~!7JYY55PPPPPPPPPPPGGBGYPPPPPGGGGGGGGGGGGGGGBBBBBBBBBBBB###&#BBBBBBBBBGGBJ             //
//                                               ..:~!7?YY55PPPGBG5PPPPPPPPPPPPPPGGGGGGGGGGGGGBGGGGGGB#BBBBBBBGGGGGP^             //
//                                                        ..:~!?5JJ5PPP5P5555PPPPPPPPPPPPPPGGGGGGGGGGB#BBBBGGGGGPJ^               //
//                                                                 ..^~!7?JY555555P55555PPPPPPPPGGGGG##BBGGGGGY~.                 //
//                                                                          ..:^!7?JY5555555555PPPGGG##BGGG5!.                    //
//                                                                                   ..:^~7?JY555PPGB##BP7:                       //
//                                                                                            ..:^!7JPY^                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DOGECOUCH is ERC721Creator {
    constructor() ERC721Creator("Doge Couch", "DOGECOUCH") {}
}