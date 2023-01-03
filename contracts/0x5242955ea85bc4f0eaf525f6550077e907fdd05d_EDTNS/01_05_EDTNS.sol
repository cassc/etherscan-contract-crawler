// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Andy Needham Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                 =                                                //
//                                               [email protected]@%:                                              //
//                                              *@@@@@*                                             //
//                                            :%@@#-%@@@-                                           //
//                                           [email protected]@@+   [email protected]@@*                                          //
//                                         :%@@%:     .#@@@-                                        //
//                                        [email protected]@@+         [email protected]@@*                                       //
//                                      .%@@%:           .#@@@-                                     //
//                                     [email protected]@@+               [email protected]@@*                                    //
//                                   .#@@%:                 .#@@@-                                  //
//                                  [email protected]@@*                     [email protected]@@#.                                //
//                                .#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-                               //
//                               [email protected]@@@@@@@######################%@@@@*                              //
//                             .#@@@@@@@@@#:                    [email protected]@@@@@-                            //
//                            [email protected]@@*:@@@[email protected]@@*.                  [email protected]@%[email protected]@@#.                          //
//                          .#@@@- [email protected]@@: .*@@@*.                [email protected]@% .#@@@=                         //
//                         [email protected]@@#.  [email protected]@@:   :#@@@+               [email protected]@%   [email protected]@@#.                       //
//                        *@@@=    [email protected]@@:     :%@@@=             [email protected]@%    .*@@@=                      //
//                      [email protected]@@@%######@@@%#######@@@@%############%@@@######@@@@#.                    //
//                      *@@@@@%%%%%@@@@@%%%%%%%%%%@@@@@@%%%%%%%%@@@@%%%%%%@@@@@-                    //
//                       :%@@%.    [email protected]@@:           [email protected]@@%:       [email protected]@%     [email protected]@@#                      //
//                         *@@@=   [email protected]@@:             [email protected]@@#:     [email protected]@%   .#@@@-                       //
//                          [email protected]@@#. [email protected]@@:              .*@@@*.   [email protected]@%  [email protected]@@#.                        //
//                            *@@@[email protected]@@:                .*@@@+  [email protected]@%.#@@@-                          //
//                             :@@@%@@@:                  :#@@@[email protected]@@@@@*                            //
//                               *@@@@@#********************@@@@@@@@@%:                             //
//                                [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*                               //
//                                 .#@@@=                     :%@@%-                                //
//                                   [email protected]@@#.                  [email protected]@@+                                  //
//                                     *@@@-               :%@@%:                                   //
//                                      [email protected]@@*             [email protected]@@+                                     //
//                                       .#@@@-         :%@@%:                                      //
//                                         [email protected]@@*.      *@@@+                                        //
//                                          .#@@@-   [email protected]@@%.                                         //
//                                            [email protected]@@*.*@@@=                                           //
//                                             .#@@@@@#.                                            //
//                                               [email protected]@@=                                              //
//                                                .*.                                               //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract EDTNS is ERC721Creator {
    constructor() ERC721Creator("Andy Needham Editions", "EDTNS") {}
}