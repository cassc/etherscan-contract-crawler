// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TimePieces by Andy Needham
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                        :++++++++++++++++++++++++++++++++++++++++++++++++-                        //
//                         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+                         //
//                          :@@@%:..................................:%@@@-                          //
//                            #@@@:                                :%@@#.                           //
//                             [email protected]@@+                              [email protected]@@+                             //
//                              :@@@#.                           #@@@:                              //
//                                #@@@-                        :%@@#.                               //
//                                 [email protected]@@+                      [email protected]@@+                                 //
//                                  :%@@#.                  .#@@@:                                  //
//                                    *@@@-                :@@@#                                    //
//                                     [email protected]@@+              [email protected]@@=                                     //
//                                      .%@@#.           #@@%:                                      //
//                                        *@@@-        :@@@#                                        //
//                                         [email protected]@@*      [email protected]@@=                                         //
//                                          .%@@%.  .#@@%:                                          //
//                                            *@@@[email protected]@@#                                            //
//                                             [email protected]@@@@@=                                             //
//                                              [email protected]@@@=                                              //
//                                             [email protected]@@@@@=                                             //
//                                            *@@@[email protected]@@*                                            //
//                                          .%@@%:  .%@@%:                                          //
//                                         [email protected]@@*      [email protected]@@=                                         //
//                                        *@@@-        [email protected]@@#                                        //
//                                      .%@@%.          .#@@%:                                      //
//                                     [email protected]@@*              [email protected]@@=                                     //
//                                    *@@@-                [email protected]@@*                                    //
//                                  .%@@%.                  .#@@%:                                  //
//                                 [email protected]@@*                      [email protected]@@+                                 //
//                                *@@@-                        :@@@#                                //
//                              :%@@%.                          .#@@%:                              //
//                             [email protected]@@+                              [email protected]@@=                             //
//                            *@@@:                                :%@@#.                           //
//                          :%@@%.                                  .%@@@:                          //
//                         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+                         //
//                        -++++++++++++++++++++++++++++++++++++++++++++++++-                        //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract TIME is ERC721Creator {
    constructor() ERC721Creator("TimePieces by Andy Needham", "TIME") {}
}