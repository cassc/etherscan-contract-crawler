// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fell Through The Porch
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//                                                    ..                                                          //
//                                                 .?5JJY?                                                        //
//                                                :GY.  .YG.                                                      //
//                               ^^^.             GY      YP             .^~^                                     //
//                             !PJ7?YY7:         !#.      .&~         :?YY?7JP~                                   //
//                            .#!    :75J:       YY        P5       :YP7:    7#.                                  //
//                            .#^       7G?      G!        ?B      ?P!       ~#.                                  //
//                             YG        .PG:   .#~        ~#.   ^PJ.        GJ                                   //
//                             .#J         ?#!  .#~        ~#   !B!         JG                                    //
//                              ^#7         ~#7  B?        JG  7#^         7B:                                    //
//               .^~~~~^:.       ^B?         ^#! JB        B? !#^         ?B:       .:^~~~~^                      //
//              !PJ!~~7?JYY?!^.   .P5.        !#..&!      !#.^&~        .55.   .^!?YYJ?7!!7J5!                    //
//              GJ        .^7JYJ!:  ?G!        55 7B      B7 GY        !G7  :7JYJ!^.        YB                    //
//              ^B7            :7YY7.:YP~      :#!~#57?7!5B:7#       !PY..75Y7^            7B~                    //
//               :Y5!             :75Y~^Y5~ :!J5PY?7!!!!!7?YPGJ!: .7GY^~Y57:             !P5:                     //
//                 ^Y5?^             ~5P~~#B5?~.             .~JPP#5^!5Y^             ^?5J^                       //
//                   .!YY?~.           ^#BY^                     ^YGGJ:           .~J5J!.                         //
//                      .~?YYJ!^:     :GP:                         ^PP.      .^!?YY?~.                            //
//                     ..   .^!?YYJ?7!#J                             Y#~~77?JJ?!^.   ..                           //
//           .^[email protected]                               [email protected]!!77??JJJJJJYYJJJ??7!~:                  //
//         ^YYJ7~^:..        ..:^~!7G#.                               .#P?7!~^:..        ..:^~7J5J:               //
//        ~#~                       G5           FELL THROUGH          PP                       .!#^              //
//        ^B?:                      B5            THE PORCH            PG                       .?B:              //
//         .7YYJ7!^^::......::^~!777GB                                 #GJ??7!~^::......:^^~!7?YY7.               //
//            .^[email protected]                               [email protected]!!!!!!7??JJJJJJJJ??!~^.                  //
//                         .^!?JJ?7!^7&!                             7&!:~!7?JJ?!:                                //
//                      ^7YYJ!^.      !BJ                          .YB~       .^7JYJ7:                            //
//                   ^?5Y!:            ?&G!.                     .7GGP~            :!YY?^                         //
//                 !5Y!.            .7PJ^J&PY~.               .!YPPG~^Y57.            .!55!                       //
//               ~PY:            .~J5?:!PJ:.!J55J7~^^:::^^~7YP5J~. :J5!:?5J^             ^YP^                     //
//              ?B^           :!J5J~ ~PY:      [email protected]?J&[email protected][email protected]^      :YP^ ~J5J!:           ~B!                    //
//              BJ       .^!JYY7^  .5P^        P5 YP      55 5P        ^GY  .^?YY?!^.       YG                    //
//              ^5Y????JJJ?!^.    ^B?         ?#.:#^      ^&^.#!         YB^    .^!?JJJ????YY:                    //
//                .:^^:.         !#~         !#^ JP        GY ^#^         ?#~         .:^^:.                      //
//                              ~#^         7#^  B7        JB  ~B~         7&~                                    //
//                             :#!         JG:  .#~        7#   ^B?         ?#:                                   //
//                             G5        :PY.   .#~        7#    .5P^        P5                                   //
//                            :&^      :JP!      B7        ?P      !GJ.      ^#.                                  //
//                            .#?   .~Y57        YP        P7        ?PJ^.   ?B.                                  //
//                             ^5Y??YJ~          ^&^      ^#.          ~JYJJYY:                                   //
//                               .:.              YB:    :#?              .:.                                     //
//                                                 JG7::7BJ                                                       //
//                                                  :7??7:                                                        //
//                                                   PEMI                                                         //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DAISY is ERC721Creator {
    constructor() ERC721Creator("Fell Through The Porch", "DAISY") {}
}