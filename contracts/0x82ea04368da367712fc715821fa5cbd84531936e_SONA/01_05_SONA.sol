// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Terra Sonalis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                            ..:^^~~!!!!!~~~^::..                                            //
//                                       :^!?JYYYYYYYYYYYYYYJJJJJ?7!~^.                                       //
//                                   :~?Y5PP5555YYYYYYYJJJJJJJJJJJJJJJJ?!^.                                   //
//                                :7YPPPPP5555555YYYYYYYJJJJJJJJJJJJJJJJJJJ7~:                                //
//                             .!YGGGPPPPPP5555555YYYYYYYJJJJJJJJJJJJJJJJJJJJJ7^                              //
//                           .7PGGGGGPPPPPPP5555555YYYYYYYYJJJJJJJJJJJJJJJJJJJJJ?~.                           //
//                          !PBGGGGGGGPPPPPPPP5555555YYYYYYYYJJJJJJJJJJJJJJJJJJJJJ?^                          //
//                        :5BBGGGGGGGGGPPPPPPPP5555555YYYYYYYYYYJJJJJJJJJJJJJJJJJJJJ7.                        //
//                       !GBBBBGGGGGGGGGGPPPPPPPP55555555YYYYYYYYYYJJJJJJJJJJJJJJJJJJJ^                       //
//                      ?BBBBBBBGGGGGGGGGGPPPPPPPPP55555555YYYYYYYYYYYJJJJJJJJJJJJJJJJJ~                      //
//                     ?BBBBBBBBBGGGGGGGGGGGPPPPPPPPP555555555YYYYYYYYYYYYJJJJJJJJJJJJJJ~                     //
//                    !BBBBBBBBBBBBGGGGGGGGGGGPPPPPPPPPP555555555YYYYYYYYYYYYYYJJJJJJJJJJ^                    //
//                   :GBBBBBBBBBBBBBBGGGGGGGGGGGPPPPPPPPPPP5555555555YYYYYYYYYYYYYYYYYJJYJ.                   //
//                   J#BBBBBBBBBBBBBBBBGGGGGGGGGGGGPPPPPPPPPPP55555555555YYYYYYYYYYYYYYYYY!                   //
//                  .GBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGPPPPPPPPPPP55555555555555YYYYYYYYYYYJ.                  //
//                  ^#BBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGPPPPPPPPPPPPP5555555555555555YYYY5:                  //
//                  !##BBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGPPPPPPPPPPPPPP5555555555555555~                  //
//                  !####BBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPP555555555P~                  //
//                  ~########BBBBBBBBBBBBBBBBBBBBBBBGGBBGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPP^                  //
//                  .B##########BBBBBBBBBBBBBBBBBBBBBBP5GGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPP5.                  //
//                   Y&#############BBBBBBBBBBBBBBBBBP. 7BBBGGGGGGGGGGGGGGGGGGGGGGPPPPPPPG?                   //
//                   ^#&&&&#############BBBBBBBBBBBBBP: ?GBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGP:                   //
//                    [email protected]&&&&&&################BBBB#P::. ..:JBBBBBBBBBBBBGGGGGGGGGGGGGGGGB!                    //
//                     [email protected]&&&&&&&&&################B^^.    ..GBBBBBBBBBBBBBBBBBBBBBBBGGBBJ                     //
//                      [email protected]@&&&&&&&&&&&&###########?:P:   ^P.J#BBBBBBBBBBBBBBBBBBBBBBBBBJ                      //
//                       [email protected]@@&&&&&&&&&&&&&&&#####B:5&!   JB^G########BBBBBBBBBBBBBBB#B?                       //
//                        [email protected]@@@@@&&&&&&&&&&&&&&&5~&#^   ~!~&#######################G~                        //
//                         .J&@@@@@@@@@&&&&&&&&&&P!#G. . .~J&&###################&BJ.                         //
//                           :5&@@@@@@@@@@@@@@&&&@&@J .Y. [email protected]&&&&&&&&&&&&&&&&&&&&#Y:                           //
//                             :J#@@@@@@@@@@@@@@@@@@Y [email protected]~ [email protected]&&&&&&&&&&&&&&&&@&B?:                             //
//                               .!5#@@@@@@@@@@@@@@@[email protected] [email protected]@@@@@&&&&&&@@@@#5~.                               //
//                                  .~JG&@@@@@@@@@@@@! G&.:&@@@@@@@@@@@#GJ~.                                  //
//                                      :~?5G#&@@@@@@G [email protected]?:@@@@@@&#G5?~.                                      //
//                                           .:~!?JY55.?GY:YYJ?!~:.                                           //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SONA is ERC721Creator {
    constructor() ERC721Creator("Terra Sonalis", "SONA") {}
}