// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mysteria: Collaboration
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                               .^~!!7?JYYYYYYJ?7!!~^.                                                               //
//                                                         :~7J5P555Y?7!~~~~~~~~!7?Y555PPJ7!:                                                         //
//                                                    .^?YP5Y?~^:.                     .:~?Y5PY?^.                                                    //
//                                                 :!YPP?~:                                  .~?5P57:                                                 //
//                                              .!5PY!.                                          .!YP57.                                              //
//                                            ^JG5!.                                                .~5GY^                                            //
//                                          ~5G?:                                                      .?P5~                                          //
//                                        ^PG7.                          .:^^:.                           !GP~                                        //
//                                      .Y#?.                         :?G#&@@&#GJ^                          ?#Y.                                      //
//                                     ~BP:         .!JY5YJ~        .Y&@@@@@@@@@@@P:        ^JY5YJ!.         :5B!                                     //
//                                    ?#?          ^G5~..:!PP.     [email protected]@@@@@@@@@@@@@G~     .5G!:..^YG~          7#J                                    //
//                                   Y#~          :BP       &Y     !&@@@@@@@@@@@@@@@G:    ?&       5B:          ^#5.                                  //
//                                  5&^           .GG       J#     ~#@@@@@@@@@@@@@@&Y:    B5       PG.           :#P.                                 //
//                                 J&^             !&~       B5     7&@@@@@@@@@@@@@J.    J#.      :#7             :&5                                 //
//                                [email protected]!              .PP       .GP.    ^P&@@@@@@@@&G!    .YB^       5G:              [email protected]                                //
//                               .&P                :BY        JG7.    :!YGBBGY7^    .!PY.       J#^                Y&.                               //
//                               [email protected]                 :GY        :J5J~.     ..     .~J5Y^        JG^                 .&5                               //
//                               &P              ~7??7Y&G~        .!J5YJ?7!~~!7?JY5J!.        ^[email protected]??7!              Y&.                              //
//                              ~&~              [email protected]?77JGY^          .^!!77777!^.          :[email protected]              ^&!                              //
//                              [email protected]               7B~    .75Y!.                           ~Y5?.    ^GJ                @Y                              //
//                              [email protected]                 !B?      ~YPJ!:.                  .:!JPY~      7B7                 &P                              //
//                              [email protected]                  ^GY. :^:.  ^?Y5JJ!^^::....::^^!?J5Y?~.  :::  JB~                  &P                              //
//                              [email protected]                  :B#GGGGG5!.  .^!7?YYYYYYYYYY?7!^.   ~YB&&&BBB^                   @Y                              //
//                              ~&~                 7BP7^. .^~5B?                      [email protected]@@@@@@@@#7                 ^&!                              //
//                               &P                ?&?         [email protected]                    [email protected]@@@@@@@@@@@@J.               Y&.                              //
//                               J&.              :@P           5#                    [email protected]@@@@@@@@@@@@@:               &5                               //
//                               .&5              .P&~         .&G                    [email protected]@@@@@@@@@@@@P.              [email protected]                               //
//                                [email protected]!              .Y#J^    ..7G5.                     Y&@@@@@@@@@@Y.              [email protected]                                //
//                                 Y&^               ^[email protected]                        [email protected]&@@@&BJ^               :&5                                 //
//                                  5#^                 ^!7!~.~B?                      7#! ^!!!^                 :#P.                                 //
//                                   5#~                       :G5                    YB^                       ^#P.                                  //
//                                    J#?                       .5G~                ^PP:                       7#Y                                    //
//                                     !B5:                       !55!:          .!YP7                       .5B!                                     //
//                                      .Y#?                        ^J5YY?7!!!?YY5J~                        7B5:                                      //
//                                        ~PG7                         .~?JYYJ?~:                         !PP~                                        //
//                                          ~5P?.                                                      .7PP!                                          //
//                                            ^YG5~.                                                .~YGY~                                            //
//                                              .75PY~.                                          .~JPP7:                                              //
//                                                 :75P5?~.                                  .~?5P57:                                                 //
//                                                    .^?YP5Y?~:.                      .:~7Y5PY?~.                                                    //
//                                                         :!?YP5555J7!!~~~~~~~~~!7JY555PY?!^.                                                        //
//                                                               :^~!7?JJYYYYYYJJ?7!~^:                                                               //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MYSTACOL is ERC1155Creator {
    constructor() ERC1155Creator("Mysteria: Collaboration", "MYSTACOL") {}
}