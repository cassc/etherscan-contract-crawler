// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BFFF00
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                     ..:^~!!777??777!!~^:..                                                     //
//                                              .^!?YPB#&&@@@@@@@@@@@@@@@@&&#BPY?!^.                                              //
//                                         :~?5B&@@@@@@@@@@@@@&&&&&&&&@@@@@@@@@@@@@&B5?~:                                         //
//                                     :!YB&@@@@@@@@#BPYJ7!~^^::::::::^^~!7JYPB#@@@@@@@@&GY!:                                     //
//                                  ^?G&@@@@@@&G5?~:.                          .:~?5G&@@@@@@&G?^                                  //
//                               :[email protected]@@@@@#P?~.                                      .~?P#@@@@@@B?:                               //
//                            [email protected]@@@@@BY~.                                              [email protected]@@@@@P!.                            //
//                          .?#@@@@@#J^                                                      ^J#@@@@@#?.                          //
//                        .J&@@@@@P!.                                                          [email protected]@@@@#J.                        //
//                       ?#@@@@&Y^                                                                ^5&@@@@#?                       //
//                     [email protected]@@@@5:                                                                    :[email protected]@@@@B~                     //
//                    [email protected]@@@@G^                                                                        ^[email protected]@@@@J                    //
//                  :[email protected]@@@&7                                                                            7&@@@@G:                  //
//                 ^#@@@@G:            :!?Y55YJ7^.                                .^7JY55Y?!:            ^[email protected]@@@#^                 //
//                ~&@@@@5.          [email protected]@@@@@@@@@#Y:                            :Y#@@@@@@@@@@B?           [email protected]@@@&~                //
//               ^&@@@@Y           :[email protected]@@@@B55P&@@@@&!                          7&@@@@&[email protected]@@@@G.           [email protected]@@@&^               //
//              :#@@@@5            [email protected]@@@@7    :777!!^                         [email protected]@@@@#^    7####&J            [email protected]@@@#:              //
//              [email protected]@@@G            [email protected]@@@@G    ~?77777?^                        [email protected]@@@@?      ......             [email protected]@@@P              //
//             [email protected]@@@&:            [email protected]@@@@G    [email protected]@@@@@@J                        [email protected]@@@@7      ......             :&@@@@7             //
//            .#@@@@?             [email protected]@@@@!   [email protected]@@@@J                        [email protected]@@@@B.    7&&&&@5              [email protected]@@@#.            //
//            [email protected]@@@#.              ^#@@@@@GYJJP&@@@@@J                         [email protected]@@@@#[email protected]@@@@#:              .#@@@@7            //
//            [email protected]@@@Y                .J#@@@@@@@@@#&@@@J                          ^5&@@@@@@@@@@#J.                [email protected]@@@P            //
//           .&@@@@~                  .~?5PPP5J~.~???^                            .!?5PPP5Y?~.                  [email protected]@@@#.           //
//           ^@@@@&:                                                                                            :&@@@@^           //
//           [email protected]@@@#.                                                                                            .#@@@@~           //
//           [email protected]@@@#.                                                                                            .&@@@@~           //
//           ^@@@@&:                                                                                            :&@@@@^           //
//           .#@@@@!                                                                                            [email protected]@@@#.           //
//            [email protected]@@@Y                   ^^                                                  ~:                   [email protected]@@@P            //
//            [email protected]@@@#.                ^[email protected]@Y                                               [email protected]&Y:                .#@@@@7            //
//            .#@@@@J              [email protected]@#?:                                                :J&@&5^              [email protected]@@@#.            //
//             [email protected]@@@&^          [email protected]@@@B:                                                  ~&@@@@P~           ^&@@@@7             //
//              [email protected]@@@G          [email protected]@[email protected]@@#!                                                [email protected]@@&[email protected]@?          [email protected]@@@P              //
//              .#@@@@5         .!~  !#@@@5:                                            ^[email protected]@@G^  !~          [email protected]@@@#.              //
//               ^&@@@@5              [email protected]@@&J.                                        ^[email protected]@@&J               [email protected]@@@&^               //
//                ~&@@@@P.              [email protected]@@&Y^                                   [email protected]@@@5:              [email protected]@@@&~                //
//                 ^#@@@@B^               ~P&@@@BJ^.                            .~Y#@@@&Y^               ^[email protected]@@@#^                 //
//                  :[email protected]@@@&?                :[email protected]@@@#5?~.                    :~?P#@@@&G7.                ?&@@@@P.                  //
//                    [email protected]@@@@G~                 ^?P#@@@@&BPY?7!~^^^^^^~!7J5G#@@@@@#57:                 [email protected]@@@@J                    //
//                     ^[email protected]@@@@5^                  .~?5G#@@@@@@@@@@@@@@@@@@@@#GY7^.                  ^[email protected]@@@@G^                     //
//                       7#@@@@@5^                     .:~7?J55PPGGPP5YJ?!~:.                     ^[email protected]@@@@#7                       //
//                        .?#@@@@@G!.                                                          [email protected]@@@@#?.                        //
//                          [email protected]@@@@#Y~.                                                    .~Y#@@@@@B?.                          //
//                             !P&@@@@@#Y!.                                              .!Y#@@@@@&P!                             //
//                               :?G&@@@@@&GJ~:                                      :~JG&@@@@@&G?:                               //
//                                  :?P&@@@@@@&B5?!^.                          .^!J5B&@@@@@@&P?:                                  //
//                                     .~JG&@@@@@@@@&BG5J?7!~^^::::::^^~!7?J5GB&@@@@@@@@&GJ~.                                     //
//                                         .~?5G#@@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@#G5?~.                                         //
//                                              .^~?YPGB#&@@@@@@@@@@@@@@@@&#BGPY?~^.                                              //
//                                                      .::^~~!!7777!!~~^::.                                                      //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BFFF00 is ERC721Creator {
    constructor() ERC721Creator("BFFF00", "BFFF00") {}
}