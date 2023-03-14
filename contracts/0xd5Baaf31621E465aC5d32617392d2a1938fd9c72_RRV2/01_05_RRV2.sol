// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Red Reflections V2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                          ..:^^^^:..                                                                          //
//                                                                     ^7J55P555YY555PP5J!^                                                                     //
//                                                                 .!5GPJ!^..        .:^!JPGY!.                                                                 //
//                                                               ^5B5!.                    :7PBY^                                                               //
//                                                             :P#J:                          :J#5:                                                             //
//                                                            7&Y.                              :5#7                                                            //
//                                                           Y&!                                  [email protected]                                                           //
//                                                          [email protected]~                                    [email protected]?                                                          //
//                                                         [email protected]                                      [email protected]^                                                         //
//                                                         PB                                       .#5                                                         //
//                                                        .&Y                                        5#                                                         //
//                                                        :@J                                        Y&.                                                        //
//                                                         #5                                        PB                                                         //
//                                                         Y&.                                      :@J                                                         //
//                                                         :&Y                                      5#.                                                         //
//                                                          [email protected]                                    [email protected]                                                         //
//                                                         [email protected]@@J                                 .5#[email protected]                                                        //
//                                                         [email protected]@@@B~                              !BP!#@#.                                                        //
//                                                         [email protected]@@@@@G!.                        .7GG7Y#@@Y                                                         //
//                                                        [email protected]@@@@@@@@#5!:                  :!5BGJ:[email protected]@@&?                                                         //
//                                                       :@@@@@@@@@@@@@&B5?!^::...:::^!?5B&@&[email protected]@@@@Y                                                         //
//                                                       :&@@@@@@@@@@@@@@@@@@@#B#P5#@@@@@@@@#&@@@@@@@@G                                                         //
//                                                       [email protected]@@@@@@@@@@@@@@@@@@@[email protected] [email protected]@@@@@@@@@@@@@@@@&~                                                         //
//                                                       [email protected]@@@@@@@@@@@@@@@@@@#[email protected]@Y.&@@@@@@@@@@@@@@@@@#:                                                         //
//                                                      [email protected]@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@#&@@@@@@@@@@@@@@&P:                                                        //
//                                                     [email protected]@@@@@@@@@@@@@@@@@@@@#[email protected]@[email protected]#@@@@@@@@@@@@@@@&BB7                                                       //
//                                                    ^&@@@@&#&@@@@@@@@@@@@@@#[email protected]@!#@#@@@@@@@@@@@@@@@@@&#P7:                                                     //
//                                                   ^&@@@@@@&@@&@@@@@@@@@@@@#[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@~                                                     //
//                                                  .#@@@@@@P!:::~Y&@@@@@@@&#BJ#B5&&@@@@@@@@@@@@@@@@#BBB&@5                                                     //
//                                                   [email protected]@@@@@@&PY77~!Y&@@#!:... ....:[email protected]@@@@@@@@@@BPJ^::  ^YG                                                     //
//                                                   #@@@@@@@@@@Y~:. ^!:.           :PG#@@#GBB5~    [email protected]                                                    //
//                                                   [email protected]@@@@@@#^!.  :. .YP55P5J!YPP7.. .~^.   .:  ~5#@@B#@@7                                                    //
//                                                     7&@@@@@J GB~ !::[email protected]&#&P#@B!~!^      ^ :[email protected]@@@@@@#!                                                     //
//                                                    ~YJ!?#@@[email protected]@#G..75PP555P5JY7!7!.:  .:JG  [email protected]@&G5J7~.                                                      //
//                                                  .PY:   [email protected]@@@@@@@P!. .~~?J!57J77!: .?G#@@[email protected]&J^                                                            //
//                                                  [email protected]!     :&@@@@@@@@@#GGB&@@@@&BPPP5P#@@@@@@@@&P~J^.. .^:                                                     //
//                                                 [email protected]@7  ^. ~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y!^.  :[email protected]                                                    //
//                                                [email protected]@#?PYP. [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P:::[email protected]                                                  //
//                                                [email protected]@&@@@B. [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#J!P&##[email protected]?                                                  //
//                                                [email protected]@@@@&^~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@5J~                                                  //
//                                                 .&@@@@@[email protected]@@@@@@&#@BBBB###@&######[email protected]&@@@@@@@@@J [email protected]@@@B                                                    //
//                                                  [email protected]@@@@[email protected]@@@@@@JYB    . .#5 .....  :&:^#@@@@@@@@[email protected]@@@B                                                    //
//                                                  [email protected]@@@@[email protected]@@@@@@^YG       G5        :&: :#@@@@@@@^[email protected]@@@P                                                    //
//                                                  ^@@@@@[email protected]@@@@@B YG       GY        :&:  [email protected]@@@@@@:[email protected]@@@7                                                    //
//                                                   [email protected]@@@#^&@@@@@J 5G       G?        :&:   [email protected]@@@@&: ~#@@&.                                                    //
//                                                   [email protected]@@@&:[email protected]@@@@~ 5B       G7        :&:   ^@@@@@@~ [email protected]@P                                                     //
//                                                   [email protected]@@@@[email protected]@@@#. 5B       G?        :#:    [email protected]@@@@[email protected]@7                                                     //
//                                                   [email protected]@@@@&&#&&@5  5P       G?        :&:    [email protected]@@@@J~^~&@~                                                     //
//                                                   [email protected]@@@@@@57~!:  5P       G?        ~&:    [email protected]@@@@7^: YB.                                                     //
//                                                   [email protected]@@@@@@@#G^   5P       G?        [email protected]~    :@@@@&:~5! :                                                      //
//                                                   :^^~&@@@@@@^   55       G?        [email protected]~     [email protected]@@@#B&B?:                                                      //
//                                                       [email protected]@@@@@~   G5       B?        [email protected]~     [email protected]@@@@@P^:.                                                      //
//                                                      [email protected]@@@@@@!   B5       J!        [email protected]~    [email protected]@@@@@&^                                                         //
//                                                      [email protected]@@#@@@^   B5                 [email protected]~    [email protected]@@@@@&^                                                         //
//                                                     [email protected]@@B~B#G    B5                 [email protected]~   [email protected]@@@@@@Y                                                         //
//                                                    ^#@&&?^P##:   GY                 [email protected]~   :@@@@@G&@@~                                                        //
//                                                   !&&#GPPPJG&G   :.                 .!.   :&@@@&?YB##~                                                       //
//                                                   YB&&&#&&&#&&~                            7&[email protected]#5PB#&@5                                                      //
//                                                   JGG&@[email protected]@@B#?                            ^@&@@@@@[email protected]@5                                                     //
//                                                    ?#B#B?B#PBB.                             [email protected]@@[email protected]@#                                                     //
//                                                     :?Y555J?7:                               .!5&@@&&B#?                                                     //
//                                                         ..                                      ^!~~^:.                                                      //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RRV2 is ERC721Creator {
    constructor() ERC721Creator("Red Reflections V2", "RRV2") {}
}