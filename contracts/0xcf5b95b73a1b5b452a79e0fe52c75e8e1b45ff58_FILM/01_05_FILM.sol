// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life in Grain
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                          ::::::::::       :::::::::::       :::          :::   :::                         //
//                         :+:                  :+:           :+:         :+:+: :+:+:                         //
//                        +:+                  +:+           +:+        +:+ +:+:+ +:+                         //
//                       :#::+::#             +#+           +#+        +#+  +:+  +#+                          //
//                      +#+                  +#+           +#+        +#+       +#+                           //
//                     #+#                  #+#           #+#        #+#       #+#                            //
//                    ###              ###########       ########## ###       ###                             //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                      ?##BB######J                                                          //
//                                .::^^^YBBGGBBBBBB5~~~^^:.                                                   //
//                               ?5PGGBBGGBBB##BBBB#####BGY.                                                  //
//                              .PGPYY5??PGGG#&GGGBBBBBBBP7                                                   //
//                              .PP5JJYJJ5GGG#&GGBBBBBBBBG7:^^^^^~~~~!!!!!7777!:                              //
//                              .Y7!!~~!!7GGGGBGGG5Y55GYYBY5?7YG5!7P5!7P?:J7:J:~                              //
//                              .J!!~~~!!?GGG5GGGGGJJJG!7GJJ: 7G? :5Y:^5?:J?~Y77                              //
//                              .J7!~~~!!?GGGYGBGPJGPYG!J#B5YY5P555555555YYY555J                              //
//                              .J7!!~~~~?GGGPGGGGJ55YG!7##P5P555P5555555YYY555J                              //
//                              .Y7!!~~~~?GGGYPGG#Y7JJG~7##P555555555555YYYY555J                              //
//                              .Y7!!~~~~7GGPJPBB#PP5YG7?##P55P5555555555YYY555J.                             //
//                              .Y7!!~~~~7GGG5PGB#PP5?G5Y##P5555555555555YY5555J.                             //
//                              .Y7!!~~~~7GGG5GBB#PJYJGYY#BPPPPPPPP55555555555PY.                             //
//                              .Y7!!~~~~7GGGPPGB#YYYYGJJ#GPPPPGGGPPPPPPPPPPPPPY                              //
//                              .57!!~~~~7GGGPPGB#G?Y5GJYB55P5555YYYYYJJJJ??777^                              //
//                              .57!!~~~~7GGGGGGG#PYPPGJYP!:..                                                //
//                              .57!~~~~~7GGG#&GG&GYPGGY5P!                                                   //
//                              .57!~~~~~7GGG##GG#Y?JYGY5P!                                                   //
//                              .57!!~~~~7GGG##GGPYPPJGYYP7                                                   //
//                              .57!~~~~~7GGG##GGPJJJYGGGP?                                                   //
//                              .57!~~~~~!GGG##GGPJP5JGBGP?                                                   //
//                              .5?7!!!!!?GGG##BG#BGGBBBBGJ.                                                  //
//                              .PGGBBBBBBBBB####B####BBBB5^                                                  //
//                               :^~~~~~~~~^^^^^^^^^^^^^^^:                                                   //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FILM is ERC721Creator {
    constructor() ERC721Creator("Life in Grain", "FILM") {}
}