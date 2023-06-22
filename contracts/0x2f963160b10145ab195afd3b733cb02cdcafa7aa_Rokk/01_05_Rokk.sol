// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: El Rokk
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                   ^-##-^                                                   //
//                                        [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@%                                        //
//                                   @@@@@@@%                      [email protected]@@@@@@                                   //
//                               @@@@@@                                  @@@@@@                               //
//                            @@@@@                                          @@@@@                            //
//                         @@@@=                                                "@@@@                         //
//                       @@@@                               ~                      @@@@                       //
//                     @@@~                                                           @@@                     //
//                   @@@^                                                               @@@                   //
//                 #@@@                                                                  *@@@                 //
//                @@@     @@@               .   .     %    =  -                    @@@     @@@                //
//              ^@@#       @@*@              @   @  %@@@[email protected] #@^  @ @              @^@@       [email protected]@#              //
//             #@@           @@ @*          @@[email protected]@@- @@@#  @@  =-=**@@-        [email protected] @#           @@@             //
//            @@@              [email protected] @@      @@@                  "    @-      @@ @.              @@@            //
//           #@@                  @%@@     [email protected] @@[email protected]%*@@   = ~ @= @=*@     @@#@                  @@@           //
//           @@                     @@*@       @@@##@%    [email protected]  [email protected]~      @" @                     @@*          //
//          @@@                       @@ @~  @    .^                 [email protected] @@                       [email protected]@          //
//         @@@                          ^@ @@                      @@ @^                          @@@         //
//         @@.        @@@@@@@@@@@@@=       @*@@                  @@%@   [email protected]@@@@%@@@@@@@=            @@         //
//        @@@            @@@    @  @@@       @%[email protected]              @[email protected]@         @@@       @@@          @@@        //
//        @@@            "@@  #     [email protected]@        @@ @"        *@ %@           @@#        @@@         [email protected]@        //
//        @@.    @       "@@         @@          *@ @@    @@ @"             @@#        @@@          @@        //
//        @@             "@@.  #^%@*@               @[email protected] @@*@                @ @      [email protected]@@           @@.       //
//        @@             "@@%***[email protected]@@@                 @* @              .   @@@@@@@@@@              @@"       //
//        @@             "@@       @@"  @@         -% @@#@ @^               @@                      @@"       //
//        @@             "@@       @@%  @@       @% @~    [email protected] @@             @@@                     @@        //
//        @@%            @@@       @@@  @@     @@*@          @"@@           @@@      #             ^@@        //
//        @@@         @@@@@@@@@@    @@[email protected]@.   @[email protected]@          ^   @@#@     %@@@@@@@@@                 @@@        //
//         @@                             [email protected] @@      *@@@@=      @@[email protected]^                             @@~        //
//         @@@                          @@ @*    @@@@@@@@[email protected]*@@@    %@ @@                          @@@         //
//          @@                        @@[email protected]      @@@@@@@@@@@@@@@@      @^@@                        @@^         //
//          @@@                     @%@@       @@@^  @@@*@@  ^@@@    #  @@@@                     @@@          //
//           @@@                 ^@ @          @@     *@@"     @@         @@[email protected]                 @@@           //
//            @@@              @@ @=            @     @[email protected]@     @            #@ @#              @@@            //
//             @@@           ^@[email protected]                @@@@%    %@@^@               [email protected]^@            @@@             //
//              @@@         @@                      @@@  #@@                     [email protected]@         @@@              //
//               @@@~                              @@@@  #@@#                               @@@               //
//                 @@@                             @@@@  #@@@                             @@@                 //
//                  @@@@                           *@@@  #@@-                           #@@@                  //
//                    @@@@        ~=                 [email protected]@@@.                 @##.      #@@@                    //
//                      @@@@       @~ @[email protected]                             # @ @ @@      @@@@                      //
//                        @@@@~    .  @@[email protected] @.  *@             *-  . @@*[email protected]       [email protected]@@@                        //
//                           @@@@*         [email protected] . @@   @%*@%@ @@ @ @@=#%        "@@@@                           //
//                              @@@@@               -=  @- %               @@@@@                              //
//                                 [email protected]@@@@@                            @@@@@@%                                 //
//                                      @@@@@@@@@@@*        [email protected]@@@@@@@@@@                                      //
//                                             *@@@@@@@@@@@@@@@@=                                             //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Rokk is ERC1155Creator {
    constructor() ERC1155Creator("El Rokk", "Rokk") {}
}