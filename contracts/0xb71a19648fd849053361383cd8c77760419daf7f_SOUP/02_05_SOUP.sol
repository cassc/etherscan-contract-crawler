// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sinclair Soup Cans
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                     ....:::^^^^^^^^^^^::::::....                                           //
//                               .:^^~~!!!!!!!!~~~!!!!77777???777!~~^^^::.                                    //
//                            .^~~~~!!!!7!~^^~!!!!!!7777777!!!!777!!^::^^^~~~^.                               //
//                           :!~~!!!7!~^^^^~~~~~~~~~~~~~~!!!!!!77777!~~!77!!7JJ7^^.                           //
//                          .?7^7^~^. :^^:^~^::......        .....:^!~:^~^:~~::??:7                           //
//                           77^!^.  7^   7.                         ~^  !: .7.?P!^                           //
//                           ^5PY!:..~^^::^7.                      :^!:..?!7YGP#5:                            //
//                            YGGGPY?!!!~~~~^.................::^^!Y5Y5PPGBBBGGGJ                             //
//                            YPPPPPPPP555YJJ?77777777??JYY5PGGGBBBBBGGGPPPPPPPPY                             //
//                            YPPPPPPPPPPPPPPPPPGGPPPGGGGGGGPPPPPPPPPPPPPPPPPPPP5.                            //
//                            5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPY:                            //
//                            PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5J:                            //
//                           .PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5?:                            //
//                           .PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP57:                            //
//                           .PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5?.                            //
//                            PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPY?.                            //
//                            5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPY?                             //
//                            5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP7                             //
//                            5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!                             //
//                            5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5!                             //
//                           .PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5!                             //
//                           .GPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5~                             //
//                           .PPPPPPPPPPPPPPPPPPPP5YJJ??JY5PPPPPPPPPPPPPPPPPPPPG?                             //
//                           .?~?YPPPPPPPPPPPPPPY!~^:^::^^~~7YPPPPPPPPPPPPPPPP55!                             //
//                           .7  .^!?YPPPPPPPPPJ^:^^^^^^^^^^^^?PPPPPPPPPP5YJ7^.~^                             //
//                           .7      .:~7JY5PPP~^^^^^^^^^^^^^^^YPP5YJ?7!^:.    ~^                             //
//                            7            .:^~^^^^^^^^^^^^^^^^^~^..           ~^                             //
//                            7.               :^^^^^^^^^^^^^^^.               !^                             //
//                            7.                :^^^^^^^^^^^^:.                !:                             //
//                            7.                 .::^:^^^:::.                  7:                             //
//                            7.     ~77! :~^.      .:...     .::^^ ~?JJ.      7.                             //
//                            7.      ^P~^Y77J^ :YJ.^5J.  ?J? ~J5J^?5^7P:      7.                             //
//                            7       ~P.^Y. 7J ~PP7?5P^ !PJP~ :P^.PJ~J7       7.                             //
//                            7       :~  77~7^ J5?PY^P~:PJ~YY.~Y: ~7!^        7.                             //
//                            7             .   ~~.~..!:^7: !~  .              !^                             //
//                            7                                                ~~                             //
//                            7                                                ^~                             //
//                           .7                                                ^!                             //
//    ..........::::::::::^^~!^                                                ^!       ..................    //
//    ^^^^^^^^^:::::::::....7?^:                                               .?^^^^^^^^^^^^^^^^^^^^^^^^^    //
//                           !~^~^:                                         .^!?7:...                         //
//                            :~^~~~^:.                              ..:^^~!77~.                              //
//                              .:^^~!!!~^:...              ..:^^~!7777!!~^:.                                 //
//                                   .::^~!777777!!!!!!!777777!!~^::.                                         //
//                                           .....:::::....                                                   //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SOUP is ERC721Creator {
    constructor() ERC721Creator("Sinclair Soup Cans", "SOUP") {}
}