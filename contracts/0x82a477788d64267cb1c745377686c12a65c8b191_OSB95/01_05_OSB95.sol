// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bouncing Heads
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                    .                ..                .                                    //
//                                ^JGB#BP?:        :?PBBBBP?:        :?PB#BGJ^                                //
//                               [email protected]@@@@@@@&~      ?&&Y~^^~Y&&?      ~&@@@@@@@@7                               //
//                               #@@@@@@@@@G     [email protected]&:      :&@~     [email protected]@@@@@@@@#                               //
//             .~?Y5Y?~.         [email protected]@@@@@@@@7     [email protected]        [email protected]?     [email protected]@@@@@@@@J         .~?Y5Y?~.             //
//            ?#&GYJYG&#?         ~5#&&&B5^      [email protected]        [email protected]?      ^5B&&&#5~         ?#&GYJYG&#?            //
//           [email protected]:     :[email protected]           .:.         [email protected]        [email protected]?         .:.           [email protected]:     :[email protected]           //
//           #@!       ^@@^                      [email protected]        [email protected]?                      ^@@^       [email protected]#           //
//           [email protected]        [email protected]                     [email protected]        [email protected]?                     [email protected]        [email protected]           //
//           .#@7        [email protected]                    [email protected]        [email protected]?                    [email protected]        [email protected]#.           //
//            [email protected]&^        [email protected]                   [email protected]        [email protected]?                   [email protected]        ^&@~            //
//             [email protected]#^        [email protected]#~                  [email protected]&:      :&@!                  ~#@J        ^#@7             //
//              [email protected]&^        [email protected]:                 [email protected]&J~^^~J&@J                 :[email protected]~        ^&@?              //
//               [email protected]@7        .?&@Y:                :JGBBBBGJ:                :[email protected]&?.        [email protected]@!               //
//                ^[email protected]        .J#@P~                  ..                  [email protected]#J.        [email protected]^                //
//                  [email protected]&7         .7G&#Y~.                              .~Y#&G!.         7&@J                  //
//                   ^[email protected]!          :?P&#GJ!:                      :!JG##P7:          [email protected]^                   //
//                     [email protected]          .~JP###G5J7!~^::::::^~!7J5G###PJ~.          [email protected]~                     //
//                       ~5&&Y^             :~7J5GGBBBB##BBBBGG5J7~:             ^Y&&5~                       //
//                         :?B&BJ^                  ........                  ^JB&B?:                         //
//                            ^JG&#P7^.                                  .^7P#&GJ^                            //
//                               :!5B##GY7^.                        .^7YG##B5!:                               //
//                                   :~?5B##BGPY?7!~~^^^^^^~~!7?YPGB##B5?~:                                   //
//                                        .:~7?Y5PGBBBBBBBBBBGP5Y?7~:.                                        //
//                                                    ....                                                    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OSB95 is ERC1155Creator {
    constructor() ERC1155Creator("Bouncing Heads", "OSB95") {}
}