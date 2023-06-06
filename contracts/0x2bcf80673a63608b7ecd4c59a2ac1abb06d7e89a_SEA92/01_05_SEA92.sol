// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seattle 1992
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                    //
//                                                                                                                                                    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                                                        //    //
//    //                                                                                                                                        //    //
//    //                                                                                                                                        //    //
//    //    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //    //
//    //    //                                                                                                                            //    //    //
//    //    //                                                                                                                            //    //    //
//    //    //                                                                                                                            //    //    //
//    //    //    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //    //    //
//    //    //    //                                                                                                                //    //    //    //
//    //    //    //                                                                                                                //    //    //    //
//    //    //    //                                                                                                                //    //    //    //
//    //    //    //                                                                                                                //    //    //    //
//    //    //    //                                                     ..                                                         //    //    //    //
//    //    //    //                                 ..:^~~!77??JJJYYYYYYYYYYYYYYJJJ???7!!~~::.                                     //    //    //    //
//    //    //    //                           :^!7?YY5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55YJ?!~:.                              //    //    //    //
//    //    //    //                      .^!?Y5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55J7^.                          //    //    //    //
//    //    //    //                    ^?YPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5?^                        //    //    //    //
//    //    //    //                 .!YPPPPPPPPPPPPPPPPPPPPPPPPPP55YYJJJJJJJJYY55PPPPPPPPPPPPPPPPPPPPPPPPPPY!                      //    //    //    //
//    //    //    //                ~YPPPPPPPPPPPPPPPPPPPPPPP5J7~::.           ..:^!?YPPPPPPPPPPPPPPPPPPPPPPPPY^                    //    //    //    //
//    //    //    //               7PPPPPPPPPPPPPPPPPPPPPPPJ~.                        ^?5PPPPPPPPPPPPPPPPPPPPPPP!                   //    //    //    //
//    //    //    //              7PPPPPPPPPPPPPPPPPPPPPPY^                             :JPPPPPPPPPPPPPPPPPPPPPPP7                  //    //    //    //
//    //    //    //             ^5PPPPPPPPPPPPPPPPPPPPPY:                               .!77777777777777777777777.                 //    //    //    //
//    //    //    //             7PPPPPPPPPPPPPPPPPPPPPP~                                                                           //    //    //    //
//    //    //    //             ?PPPPPPPPPPPPPPPPPPPPP5:                                                                           //    //    //    //
//    //    //    //             ?PPPPPPPPPPPPPPPPPPPPP5:                                                                           //    //    //    //
//    //    //    //             !PPPPPPPPPPPPPPPPPPPPPP7                                                        .                  //    //    //    //
//    //    //    //             .5PPPPPPPPPPPPPPPPPPPPP5~                               .?YYYYYYYYYYYYYYYYYYYYYYY:                 //    //    //    //
//    //    //    //              ^5PPPPPPPPPPPPPPPPPPPPP57:                            ^YPPPPPPPPPPPPPPPPPPPPPPP!                  //    //    //    //
//    //    //    //               ^YPPPPPPPPPPPPPPPPPPPPPP5?~:                     .^!YPPPPPPPPPPPPPPPPPPPPPPP5!                   //    //    //    //
//    //    //    //                .75PPPPPPPPPPPPPPPPPPPPPPP5Y?7!~^:::::::::^^~!?J5PPPPPPPPPPPPPPPPPPPPPPPPPJ:                    //    //    //    //
//    //    //    //                  :7YPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555555PPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5?^                      //    //    //    //
//    //    //    //                    .^7Y5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5?!.                        //    //    //    //
//    //    //    //                        :~7JY5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55J?!:.                           //    //    //    //
//    //    //    //                             .:~!7?JYY55PPPPPPPPPPPPPPPPPPPPPPPPPPPP555YJJ?7~^:.                                //    //    //    //
//    //    //    //                                     ..::^^~~~~!!!!!!77!!!!!!~~~~^^::..                                         //    //    //    //
//    //    //    //                                                                                                                //    //    //    //
//    //    //    //                                                                                                                //    //    //    //
//    //    //    //                                                                                                                //    //    //    //
//    //    //    //                                                                                                                //    //    //    //
//    //    //    //                                                                                                                //    //    //    //
//    //    //    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //    //    //
//    //    //                                                                                                                            //    //    //
//    //    //                                                                                                                            //    //    //
//    //    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //    //
//    //                                                                                                                                        //    //
//    //                                                                                                                                        //    //
//    //                                                                                                                                        //    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                                                    //
//                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SEA92 is ERC721Creator {
    constructor() ERC721Creator("Seattle 1992", "SEA92") {}
}