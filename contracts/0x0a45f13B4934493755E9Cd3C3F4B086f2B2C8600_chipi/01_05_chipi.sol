// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: chippi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//          ,--.     ,--.              ,--.                                                                   //
//     ,---.|  ,---. `--' ,---.  ,---. `--'                                                                   //
//    | .--'|  .-.  |,--.| .-. || .-. |,--.                                                                   //
//    \ `--.|  | |  ||  || '-' '| '-' '|  |                                                                   //
//     `---'`--' `--'`--'|  |-' |  |-' `--'                                                                   //
//                       `--'   `--'                                                                          //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    ~~~~~~~~~~~~~~~~~~~~^^^::..                                                                             //
//    555555YYYYJJYYYJJJYYY55555YYYJ?7~^:.                                                                    //
//                           ...:^^~7?Y5PP5Y?!^:.                                                             //
//                                      .:^~7?YYYJ7~:.                                                        //
//                                             .:^7J55Y7^.                                                    //
//                                                  .^!JPPY7^.                                                //
//                                                      .:!5GP7:                                              //
//                                                          :7PGJ^                                            //
//                                                            .~YG5~                                          //
//                                                               ^YB5^                                        //
//                                                                 ^5#Y:                                      //
//                                                                  .7BB~                                     //
//                                                                    ^P#!                                    //
//                                                                     :5#!                                   //
//                                            ..            .^^.        .Y#7                                  //
//                                          .YBBY^          ?&&B!        .Y&?                                 //
//                                          :#@@@G.         [email protected]@@#~        .5&!                                //
//                                          [email protected]@@&!         :#@@@5         :G#^                               //
//                                           ^#@@@5          7&@@G.         ~&P.                              //
//                                            ^YP5!           ~JJ~           J&7                              //
//                                                                           ^#G.                             //
//                                                                           .G&^                             //
//                                                                            [email protected]!                             //
//                                                                            [email protected]                             //
//                                                                            ~&5                             //
//                                    .^^^^^::::.........                     ^&P                             //
//                                    7GBBBBGGGGPPPPPPPPPPPP555YYJJ??7~.      ^&P                             //
//                                     .::::::::::^^^~~!!77??JJJYY55PP5:      :#P                             //
//                                                                   .        :#G.                            //
//                                                                            .BB.                            //
//                                                                            .GB.                            //
//                                                                             PB:                            //
//                                                                             Y&^                            //
//                                                                             Y&~                            //
//                                                                             [email protected]!                            //
//                                                                             [email protected]!                            //
//                                                                                                            //
//                                                                                                            //
//    500 hand-drawn characters that inhabit the bankless locations, by perchy                                //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract chipi is ERC721Creator {
    constructor() ERC721Creator("chippi", "chipi") {}
}