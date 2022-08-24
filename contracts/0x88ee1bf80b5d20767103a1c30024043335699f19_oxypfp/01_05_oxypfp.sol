// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xyPFP
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                         .:::.                                                        //
//                                                    :!YGGGPPGGBPJ~.                                                   //
//                                                  !P&@#?^.  .:[email protected]@#Y^                                                 //
//                                                ^[email protected]@@J          ^#@@&Y.                                               //
//                                               [email protected]@@@J            :#@@@B^                                              //
//                                              [email protected]@@@G              [email protected]@@@&^                                             //
//                                             [email protected]@@@@~               [email protected]@@@#:                                            //
//                                            :&@@@@B                [email protected]@@@@5                                            //
//                                            [email protected]@@@@Y                :&@@@@@^                                           //
//                                           .#@@@@@7                 [email protected]@@@@J                                           //
//                                           ^@@@@@@!                 [email protected]@@@@P                                           //
//                                           [email protected]@@@@@~                 [email protected]@@@@B                                           //
//                                           [email protected]@@@@@~                 [email protected]@@@@B                                           //
//                                           [email protected]@@@@@~                 [email protected]@@@@G                                           //
//                                           :&@@@@@!                 [email protected]@@@@5                                           //
//                                            [email protected]@@@@?                .#@@@@@7                                           //
//                                            [email protected]@@@@5                :&@@@@#.                                           //
//                                             [email protected]@@@#.               [email protected]@@@@?                                            //
//                                             :#@@@@7               [email protected]@@@5                                             //
//                                              ^#@@@#.             [email protected]@@@P                                              //
//                                   .~~~~~~.    :[email protected]@@P.           !&@@@J    .~~~~~~.                                   //
//                                    [email protected]@@@@?      [email protected]@B~        [email protected]@@P^    ^[email protected]@@@&7                                    //
//                                     ~#@@@@Y.      !5#@BY7!!!?P&@BJ^     7&@@@@G:                                     //
//                                      [email protected]@@@B^       .^7JYYYYJ?~:      [email protected]@@@@J                                       //
//                                        7&@@@@?                       ^[email protected]@@@B~                                        //
//                                         ^[email protected]@@@P:                    7&@@@@5.                                         //
//                                          [email protected]@@@&7                 [email protected]@@@&!                                           //
//                                            !&@@@@P.              ^[email protected]@@@P:                                            //
//                                             :[email protected]@@@#!            7&@@@@?                                              //
//                                               [email protected]@@@@Y          [email protected]@@@B^                                               //
//                                                ~#@@@@B^      ^[email protected]@@@Y.                                                //
//                                                 [email protected]@@@&?    7&@@@#!                                                  //
//                                                   ?&@@@@[email protected]@@@P:                                                   //
//                                                    ^[email protected]@@@@@@@@&?                                                     //
//                                                     [email protected]@@@@@@B^                                                      //
//                                                      :#@@@@@Y  7^                                                    //
//                                                     !#@@@@&! [email protected]&7                                                   //
//                                                    [email protected]@@@@P: !#@@@@5.                                                 //
//                                                  :[email protected]@@@@?  :&@@@@@@B^                                                //
//                                                 !&@@@@B^    ^[email protected]@@@@@&7                                               //
//                                                [email protected]@@@@Y.      [email protected]@@@@@@5.                                             //
//                                              ^[email protected]@@@#!          [email protected]@@@@@@B^                                            //
//                                             7&@@@@P.            ~#@@@@@@@?                                           //
//                                           [email protected]@@@&?               :[email protected]@@@@@@P.                                         //
//                                          ^[email protected]@@@G^                  [email protected]@@@@@@#~                                        //
//                                         7&@@@@J                     !&@@@@@@@?                                       //
//                                       [email protected]@@@#~                       ^[email protected]@@@@@@P.                                     //
//                                      ^[email protected]@@@5.                         [email protected]@@@@@@#~                                    //
//                                     ?&@@@&7                             [email protected]@@@@@@@J                                   //
//                                   [email protected]@@@G:                               ~#@@@@@@@P:                                 //
//                                  ^[email protected]&&@B                                  :[email protected]&&&&&@B~                                //
//                                  :^:::::                                    :::::::^:                                //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract oxypfp is ERC721Creator {
    constructor() ERC721Creator("0xyPFP", "oxypfp") {}
}