// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Don't lick your CHECK
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                          :^!?Y55PP55J?!~^:... ...:^~!7?Y5PGGGPY?!^.                                          //
//                                     .~?P#@@@&#BBGGBB#&@@@@&&##&&&@@@@@&#BGPGGB#&@@&B57^                                      //
//                                  .!5&@@#P?!^.        .:^~!7?JJJ??7!~^:.        .^!?P#@@#5!.                                  //
//                                ~5&@&P7^                                              ^[email protected]@&5~                                //
//                             [email protected]@G7.                                                    :[email protected]@B?.                             //
//                           .?#@&Y^                                                          ^Y&@&J.                           //
//                          ?#@&J:                                                              :J&@&?.                         //
//                        [email protected]@Y:                .:^^~!7777777!!!!!77777???777!~^:.                :[email protected]@#!                        //
//                      :[email protected]@P^          .:~7J5GB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BP5J!^:           ^[email protected]@P:                      //
//                     7&@&7       :~?5G#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#GY7~:       7&@&7                     //
//                   [email protected]@P:   .^75B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&B5?~.   :[email protected]@5.                   //
//                  ^[email protected]@? .~?P#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GJ~. ?&@B^                  //
//                 !&@&J7P#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G??&@&!                 //
//                [email protected]@@&&@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@&&&&&###&&&@@@@@@@@@@@@@@@@@@@@&&@@@?                //
//               [email protected]@@@@@@@@@@@@@@@@@@@GJ7!^^::.....::::^^^^^[email protected]@@@@@P7~^^^::::.......:^^[email protected]@@@@@@@@@@@@@@@@@@@Y               //
//              [email protected]@@@@@@@@@@@@@@@@@@B^                        [email protected]@@@Y                        ^[email protected]@@@@@@@@@@@@@@@@@@7              //
//              [email protected]@@@@@@@@@@@@@@@@@#.                         ^@@@@^                         .#@@@@@@@@@@@@@@@@@@~              //
//               [email protected]@@&@@@@@@@@@@@@@J                           [email protected]@B                           [email protected]@@@@@@@@@@@@&@@@P               //
//               [email protected]@J^JP#@@@@@@@@@?                           [email protected]@?                           [email protected]@@@@@@@@#[email protected]@#:               //
//                :#@@7  .:!?5G#@@@5                            G#.                           [email protected]@@#G5?!:.  [email protected]@&^                //
//                 :[email protected]@J       .~&@#.                           ^~                            [email protected]&~        [email protected]@#^                 //
//                  [email protected]@G:       [email protected]@~                                                        ^@@5       :[email protected]@P:                  //
//                    7#@&?.     [email protected]@Y                          .::.                          [email protected]@!     .?&@&?                    //
//                     [email protected]@#7.   .#@&.                    ...7G&@@&G7 ..                    ^@@B    .7#@@5:                     //
//                       ^[email protected]@#J:  [email protected]@J                 ~5B###@@@@@@@@###B5~                 [email protected]@?  :J#@@5^                       //
//                         :Y#@@P!:#@&:               [email protected]@@@@@@@@@@@@@@@@@@@J               [email protected]@#:[email protected]@#Y:                         //
//                           [email protected]@&&@@P               #@@@@@@@@@@@@@[email protected]@@@@B               [email protected]@&&@&P!.                           //
//                              .!5#@@@?            :J&@@@@@@@@@@@@? [email protected]@@@@&J.            [email protected]@@#5!.                              //
//                                  ~#@@~          :#@@@@@@@@@@@@B^[email protected]@@@@@@@#:          ~&@#!                                  //
//                                   [email protected]@&^         [email protected]@@@@@@B^[email protected] ~#@@@@@@@@@@!         :#@@~                                   //
//                                    [email protected]@&^         [email protected]@@@@@@B7.: [email protected]@@@@@@@@@@5         :[email protected]@7                                    //
//                                     [email protected]@&!         ~&@@@@@@@#[email protected]@@@@@@@@@&^         ^#@@7                                     //
//                                      ~#@@J         [email protected]@@@@@@@@@@@@@@@@@@@Y         !&@&!                                      //
//                                       :[email protected]@B~        7G#&&&@@@@@@@@&&&#P!        [email protected]@G:                                       //
//                                         7#@@5:        .:..J#@@@@B?..:.        .?&@&?                                         //
//                                          .J&@@5^            :^^:            :J#@&Y.                                          //
//                                            [email protected]@B?^                      :[email protected]@#?:                                            //
//                                               ~Y#@@#57~:.          .:[email protected]@#5~                                               //
//                                                 .^?P#@@@#BGPP55PGB#&@@@#P?^.                                                 //
//                                                      :~7J5PGGBBGGP5J7~:                                                      //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract YHIB is ERC1155Creator {
    constructor() ERC1155Creator("Don't lick your CHECK", "YHIB") {}
}