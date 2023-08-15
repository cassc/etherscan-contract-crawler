// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE DYOR
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                    ....   ..:.....   .......         ....                                  //
//                                  ...  .^!?JJYYYYJJ?!^.    .^~!77?77!~.  ...                                //
//                                ...  ^7YYYYYYYYYYYYYYYY?7?JYYYYYYYYYYYY7. ...                               //
//                               ..  :?YYYYYYYYYYYYYYYYYYY5PYYYYYYYYYYYYYYY: ....                             //
//                              ..  !YYYYYYY555YYYYYYYY55555PYYYYYYY5555YYYY.   ....                          //
//                             ..  7YYYYYYYYYYYYYYYYYYYYYYY5PP5YYYYYYYYYYYY5J?7~.  ...                        //
//                          ....  !5YYYYYYYYYYYYYY5555555Y555PP55YYYY555555555555?:  ..                       //
//                        ...  :~?5YYYYYYYYYYY5555555YYYYYYYYY55PP555555YYYYYYY55P5J. ..                      //
//                       ..  ^JYYPYYYYYYYYY555555YYYYYYY555YJ?JJJY5YYYYJJY5PGGPY?JY5J. ..                     //
//                      ..  ~YYYY5YYYYYYY55555YYJJJJ?JGGY&&#BP7!!?J777!!5&#Y&B#&P!!!J: ..                     //
//                     ..  !YYYYYYYYYYYYYYYYYY5Y?77!7#@&#@P!#@B?J57777!?@@@&&Y5&&YJY~  ..                     //
//                    ..  !YYYYYYYYYYYYYYYYYYY55555YYBBBBBGPGPP555YYYYYYPPPPPP555J!^  ..                      //
//                   ..  !5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY55YYYYYYYYYYJJJJYYY?!.  ...                       //
//                  ..  !5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYY555YYYYYYYY5555555555Y^   ...                         //
//                  .. :5YYYYYYYYYYYYYYYYYYYYYYYYYYYYY5YYYYYYYYYYYYYYYYYYYYYYYJ!. ..                          //
//                  :  ?YYYYYYYYYYYYYYYYYYY555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ. ..                         //
//                 ..  YYYYYYYYYYYYYYYYYYY55YY555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5!  ..                        //
//                 ..  YYYYYYYYYYYYYYYYY5YY55Y55555555YYYYYYYYYYYYYYYYYYYYYYY55555?  :.                       //
//                  :  ?YYYYYYYYYYYYYYYYYPYYY555555555555555555555Y555555555555Y5Y!  ..                       //
//                  .. :5YYYYYYYYYYYYYYYYY55YYY555555555555555555555PPPPPPPPP55P!   :.                        //
//                  .:  ^YYYYYYYYYYYYYYYYYYYYYYYYYYY5555555555555555555PGGBBGGGP7:    .....                   //
//                  ..   :?5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYY55YY55555555555P5?J5GGBGPJ7^.   ......              //
//                ...  !JY5PPP55YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?!:   .:~?YPB#BG5?!:.  ...             //
//               ..  :YPP5555PPPP5555555YYYYYYYYYYYYYYYYYYYYYYYYYY?7~^.   .....   .^!JYPGBGPY7. ..            //
//              ..  ~5P5555555555555555555555555555555555555555PP57:   .:.    .....    .:~7J5?. ..            //
//             ..  !P555555555555555555555555555555555PPPP55555555PPY?^  ..        ......      ..             //
//             .. :P5555555555555555555555555555555555555555555555555PP?. ..            ........              //
//            ..  ?P555555555555555555555555555555555555555555555555555PJ  ..                                 //
//            .  ~P55555555555555555555555555555555555555555555555555555PJ. ..                                //
//            .  7P555555555555555555555555555555555555555555555555555555P?  :                                //
//            .  !P55555555555P5555555555555555555555555555555555555555555Y  ..                               //
//            .  !P55555555555P555555555555555555555555555555555555PP55555Y. ..                               //
//            .  !P55555555555P5555555555555555555555PPPPPPP55555PPPP555555. ..                               //
//            .  !P55555555555P5555555555555555555555P555555555555PPP555555: ..                               //
//            .  !P55555555555P5555555555555555555555P555555555555PPP55555P^ ..                               //
//            .  !555555555555P5555555555555555555555P555555555555PPP55555P^ ..                               //
//            .. .:::::::::::::::::::::::::::::::::::::::::::::::::::::::::. ..                               //
//             ...............................................................                                //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PEPE is ERC1155Creator {
    constructor() ERC1155Creator("PEPE DYOR", "PEPE") {}
}