// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PSY10 by Kazuhiro Aihara
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//                                                     &@@@@@@@@@                          //
//                                            @@@@@@@ @@@@@@@@@@@@@                        //
//                                          @@@@@@@@@@@@@@@@@@@@@@@                        //
//                    &@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@                        //
//           (@@@@@% @@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@                         //
//         @@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@               ..          //
//        @@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@              @@@@@@@         //
//        @@@@@@@@@@@@@@@@@@@@@@@                                         ,@@A@@I@@.       //
//         @@@@@@@@@@@@@@@@@@@@&                                          @@@@ @@@@        //
//           %@@@@@@@@@@@@@@@                                            @@@@  @@@@@       //
//                                                                       @@@@@@@@@@@       //
//                                                     /@@@(            @H@@A@@.@R@A@      //
//                                                 @@@@@@@@@@@@@        @@@@    &@@@@      //
//             @@@@                               @@@@@@@@@@@@@@@@     &@                  //
//     @@@@@  @@@@             #&&(               @@@@@@@@@@@@@@@@@@                       //
//     @K@@A Z@U@         *@@@@@@@@@@@@,           @@@@@@@@@@@@@@@@@@&                     //
//     @@@@@@@@@         @@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@                    //
//     @@@@@@@@@@,       @@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@                    //
//     @@@@@ @@@@@@       @@@@@@@@@@@@@@@@@            .@@@@@@@@@@@@@@@@                   //
//     @H@I@  &@R@O@       @@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@                   //
//     @@@@@                @@@@@@@@@@@@@@@@@@&   ,(@@@@@@@@@@@@@@@@@@@@                   //
//                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    //
//                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     //
//                               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                       //
//                                  %@@@@@@@@@@@@@@@@@@@@@@@@@@@                           //
//                                          .&@@@@@@@&/                                    //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract PSY10 is ERC721Creator {
    constructor() ERC721Creator("PSY10 by Kazuhiro Aihara", "PSY10") {}
}