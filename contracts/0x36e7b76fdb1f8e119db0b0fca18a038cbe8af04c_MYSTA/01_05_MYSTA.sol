// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mysteria
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                          .....:....                                                                          //
//                                                               .:^!?J5PGGBBBBBBBBBBBBGGP5Y?7~:.                                                               //
//                                                          :~?5GBBBG5Y?7!~^::::..::::^^~!?J5PGBBGPJ!^.                                                         //
//                                                     .^?PB#B5J!^.                            .:~?5G##PJ!.                                                     //
//                                                  :?P##PJ~:                                        .^?5B#GJ~                                                  //
//                                               ^JB#GJ~.                                                 ^?P##5~.                                              //
//                                            :?B&G?:                                                        .!P&#Y^                                            //
//                                          ^5&#J:                                                              .7G&G!                                          //
//                                        [email protected]!                                                                    ^5&#?.                                       //
//                                      [email protected]^                                 .:^^^:.                                :J&#?                                      //
//                                    :[email protected]~                               :75B&&@@@&#GJ~                               :[email protected]!                                    //
//                                   [email protected]#!             .:^^:.            :5&@@@@@@@@@@@@@B7             :^~^.             ^[email protected]                                  //
//                                 :[email protected]            !P#BGGB#P!         !&@@@@@@@@@@@@@@@@@P.        ^5BBGGB#BJ.            [email protected]#~                                 //
//                                ~&&!            [email protected]^.  .^[email protected]      ^@@@@@@@@@@@@@@@@@@@@5       [email protected]!.   :?&#~            ^[email protected]                                //
//                               [email protected]#^             [email protected]        [email protected]      [email protected]@@@@@@@@@@@@@@@@@@@&:     ^@#.       [email protected]             [email protected]                               //
//                              [email protected]              [email protected]        [email protected]      [email protected]@@@@@@@@@@@@@@@@@@@&:     [email protected]        [email protected]               [email protected]                              //
//                             [email protected]               [email protected]         [email protected]     ^@@@@@@@@@@@@@@@@@@@@5     :&&^        [email protected]                [email protected]                             //
//                            [email protected]#:                 [email protected]!        :#@~     !&@@@@@@@@@@@@@@@@@5.    [email protected]        .#@^                 [email protected]                            //
//                           .#@~                  ^@#:        ^[email protected]?     :5&@@@@@@@@@@@@@G!     ~#@7         [email protected]                  .#@~                           //
//                           [email protected]                    [email protected]        [email protected]~     :75B#&@@&&BPJ^     :[email protected]^         [email protected]                    [email protected]                          //
//                          ^@#.                     [email protected]         ^P&B?:      .:^^:.      .!P&B!          [email protected]                     [email protected]?                          //
//                          [email protected]                       !&#~          :?G#BY7^:.       .^!JP#BY~          :[email protected]                       [email protected]                         //
//                         .#@^                .5PPPPPP#@@5:           :!YPBBBGGPPGGBBBG57^            7&@&PPPPPPP~                 [email protected]~                         //
//                         [email protected]                  [email protected]&7~!!~~7#&J:              .:^~~~~~^:.             .7B&[email protected]:                 [email protected]                         //
//                         [email protected]                   [email protected]:     .7B&5~                                  ^J#&Y:      [email protected]                  [email protected]                         //
//                         [email protected]                    ~#&!       ~5##5!.                          .^JG&G7.      :[email protected]?                    [email protected]                         //
//                         [email protected]                     :[email protected]        .!5B#GY7^.                .^!JPB#P7:        ~&&!                     [email protected]#.                        //
//                         [email protected]                       [email protected]:~!7!~^.   :!JPBBBGPYJ???7??JY5PGBBG57^.   :~!7!~:[email protected]^                      [email protected]                         //
//                         [email protected]                       ^#@#BPPPGB#P!.     .^~7?JY5555YYJ7!^:.     ^YB#[email protected]@7                       [email protected]                         //
//                         ^@#.                    [email protected]!:     [email protected]~                          [email protected]!:     [email protected]~                     [email protected]?                         //
//                          [email protected]~                   [email protected]?           ^#@~                        [email protected]?           ^&@~                   .#@^                         //
//                          [email protected]                   [email protected]             [email protected]                        [email protected]             [email protected]                   [email protected]                          //
//                          .#@^                  [email protected]             [email protected]                        [email protected]             [email protected]                   [email protected]~                          //
//                           [email protected]                  [email protected]?           ^#@~                        [email protected]?           ^&@~                  [email protected]                           //
//                            [email protected]                  [email protected]:     .~Y&B~                          [email protected]!:     [email protected]~                  ^@#:                           //
//                            [email protected]!                   ^YB#BGPPGB#@G                              [email protected]&#BGPPG##P!                   :#@~                            //
//                             ^&@~                     :~!7!~:[email protected]                           [email protected]^:~!7!~^.                    [email protected]                             //
//                              ^#@!                             [email protected]:                         [email protected]                            :[email protected]                              //
//                               :[email protected]?                             ~&&~                      :[email protected]                             ~#@!                               //
//                                [email protected]                            :[email protected]:                   7&&7                             [email protected]#^                                //
//                                  [email protected]#!                             7#&5~.             ^J#&Y:                            :[email protected]                                 //
//                                   ^[email protected]:                             ~5##GY7!~^^^~7JPB#G7.                            [email protected]#!                                   //
//                                     7#@J.                              ^7J5GGBBGGPY?~.                              7#@J.                                    //
//                                      .?#&J:                                                                      [email protected]:                                      //
//                                        .?#&5^                                                                  :J#&Y:                                        //
//                                           !G&B?:                                                            .!P&B?.                                          //
//                                             :JB&G?:                                                      .!P##5~                                             //
//                                                ^JG#BY!:                                              .~JG#B5~.                                               //
//                                                   :75B#GY7^.                                    .:!JG##P?^                                                   //
//                                                       :!YGB#G5J7~:.                      .:^!?YGB#G5?^.                                                      //
//                                                           .^!?5GBBBBGP5YJ??777!777?JJYPPGBBBG5J7^.                                                           //
//                                                                  .:^!7?JY55PPPPPP55YJJ7!~^.                                                                  //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MYSTA is ERC721Creator {
    constructor() ERC721Creator("Mysteria", "MYSTA") {}
}