// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE VOID
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                             //
//                                                                                                                                             //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////     //
//    //                                                                                                                                //     //
//    //                                                                                                                                //     //
//    //                                                                                                                                //     //
//    //                                                                                                                                //     //
//    //                                                                @                                                               //     //
//    //                                                              @@@@@                                                             //     //
//    //                                                      @@@@@@@@@@@@@@@@@@@#                                                      //     //
//    //                                             *@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@                                              //     //
//    //                                        @@@@@@@@@@@      @@@@@      @@@@    @@@@@@@@@@@@                                        //     //
//    //                      @@@@@@@@@@@   @@@@@@@@           @@@@@         @@@@@         @@@@@@@@@        @@@@@@                      //     //
//    //                      @@@@  @@@@@@@@@@@@@@@@@@@      @@@@@             @@@@       @@@@@@@@@@@@@@@@@@@@@@@@@                     //     //
//    //                      @@@@            @@@@@@       @@@@@                 @@@@       @@@@@@             @@@@                     //     //
//    //                      @@@@         @@@@@@       @@@@@@                     @@@@@       @@@@@@          @@@@                     //     //
//    //                      @@@@      @@@@@@     @@@@@@@@@@                        @@@@@@@@     @@@@@@       @@@                      //     //
//    //                       @@@   @@@@@@     @@@@@@@                                  @@@@@@@     @@@@@    @@@@                      //     //
//    //                     @@@@@ @@@@@     @@@@@@.         @@@@@@@@@@@@@@@@@@@@@@          @@@@@@     @@@@/ @@@@                      //     //
//    //                    @@@@@@@@@@     @@@@@/       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@     @@@@@@@@@@                    //     //
//    //                   @@@@@@@@@     @@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@     @@@@@@@@@                   //     //
//    //                 &@@@@  @@     @@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@     @@@ @@@@                  //     //
//    //                ,@@@@         @@@@       @@@@@@@@         @@@@@@@@@@@@          @@@@@@@       @@@@         @@@@                 //     //
//    //                @@@@         @@@@      @@@@@@                  @@@                  @@@@@       @@@         @@@@                //     //
//    //               @@@@      ,@@@@@@      @@@@@                                           @@@@       @@@@@       @@@@               //     //
//    //              [email protected]@@    @@@@@@,        @@@@&                                             @@@@         @@@@@/   @@@@               //     //
//    //              @@@@@@@@@@@           @@@@@           @@@@@@            @@@@@@@           @@@@           @@@@@@ @@@@              //     //
//    //              @@@@@@@               @@@@@         @@@@@@@@          @@@@@@@@            @@@@               @@@@@@@              //     //
//    //           @@@@@@@                  @@@@@         @@@@@@            @@@@@@             @@@@@                  @@@@@@            //     //
//    //          @@@@@                     @@@@@@        @@@@@@@@          @@@@@@@@           @@@@@                      @@@@@         //     //
//    //             @@@@@                  @@@@@@@        @@@@@@@@          @@@@@@@@         @@@@@@                   @@@@@            //     //
//    //              @@@@@@@@               @@@@@@@    @    %@@@               @@      @   /@@@@@@                ,@@@@@@              //     //
//    //              @@@@ @@@@@@             @@@@@@@@   @@ @#    @           @    @@ @@   @@@@@@@              @@@@@@@@@               //     //
//    //              @@@@@   @@@@@@@          @@@@@@@@@  @@@@@  @@@   @@%   @@@ #@@@@*  @@@@@@@@           @@@@@@   @@@@               //     //
//    //               @@@@      @@@@@@@         @@@@@@@@@  @  @@@@@@@@@@@@@@@@@@@  @ @@@@@@@@@*         @@@@@@     @@@@@               //     //
//    //               @@@@@        #@@@@          @@@@@@@@@@   @   @@@@ @@@@   (   @@@@@@@@@#         @@@@@       %@@@@                //     //
//    //                @@@@@  @      @@@@@          @@@@@@@@@@@     @     @    *@@@@@@@@@@           @@@@        /@@@@                 //     //
//    //                 @@@@@ @@@     @@@@@            @@@@@@@@@@@@         @@@@@@@@@@@            &@@@@    @@@ @@@@@                  //     //
//    //                  @@@@@@@@@@     @@@@@             @@@@@@@@@@@@@ @@@@@@@@@@@@              @@@@    @@@@@@@@@@                   //     //
//    //                   @@@@@@@@@@@     @@@@@&               @@@@@@@@@@@@@@@@@                @@@@@@   @@@@@@@@@@@                    //    //
//    //                     @@@@@  @@@@.    @@@@@@.                                         @@@@@@%   @@@@@  @@@@@                     //     //
//    //                      @@@(    @@@@@     @@@@@@@                                  @@@@@@@@   @@@@@@    @@@                       //     //
//    //                     [email protected]@@       @@@@@@     @@@@@@@@@                        @@@@@@@@@@   &@@@@@@      @@@                       //     //
//    //                     @@@@          @@@@@@      @@@@@@@                    [email protected]@@@@@     @@@@@@@         @@@                       //     //
//    //                     @@@@             @@@@@@*     @@@@@                  @@@@      @@@@@@@            @@@@                      //     //
//    //                     @@@@@@@@@@@@@@@@@@@@@@         @@@@@              @@@@@     /@@@@@@@@@@@@@@@@@@@@@@@@                      //     //
//    //                     @@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@          @@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@                      //     //
//    //                                      *@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@              @@                       //     //
//    //                                           @@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@                                            //     //
//    //                                                  %@@@@@@@@@@@@@@@@@@@@@@@@@@                                                   //     //
//    //                                                             @@@@@&                                                             //     //
//    //                                                               @@                                                               //     //
//    //                                                                                                                                //     //
//    //                                                                                                                                //     //
//    //                                           THE VOID, A SoulWorld Collection by Karalang                                        //      //
//    //                                                                                                                                //     //
//    //                                                                                                                                //     //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////     //
//                                                                                                                                             //
//                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract THEVOID is ERC721Creator {
    constructor() ERC721Creator("THE VOID", "THEVOID") {}
}