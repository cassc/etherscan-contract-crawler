// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Don't Fade the Checks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//                                                                     FFFFFFFFFFFF    //
//                                                                    FFFFFFFFFFFF     //
//                                                                   FFFFFFFFFFFF      //
//                                                                  FFFFFFFFFFFF       //
//                                                                 FFFFFFFFFFFF        //
//                                                                FFFFFFFFFFFF         //
//                                                               AAAAAAAAAAAA          //
//                                                              AAAAAAAAAAAA           //
//                                                             AAAAAAAAAAAA            //
//                                                            AAAAAAAAAAAA             //
//                                                           AAAAAAAAAAAA              //
//                                                          AAAAAAAAAAAA               //
//                                                         DDDDDDDDDDDD                //
//                                                        DDDDDDDDDDDD                 //
//                                                       DDDDDDDDDDDD                  //
//                                                      DDDDDDDDDDDD                   //
//                                                     DDDDDDDDDDDD                    //
//                                                    DDDDDDDDDDDD                     //
//                              EEEEEEEEEEEE         EEEEEEEEEEEE                      //
//                               EEEEEEEEEEEE       EEEEEEEEEEEE                       //
//                                EEEEEEEEEEEE     EEEEEEEEEEEE                        //
//                                 EEEEEEEEEEEE   EEEEEEEEEEEE                         //
//                                  EEEEEEEEEEEE EEEEEEEEEEEE                          //
//                                   EEEEEEEEEEEEEEEEEEEEEEE                           //
//                                    DONTFADETHECHECKSDONT                            //
//                                     FADETHECHECKSDONTFA                             //
//                                      DETHECHECKSDONTFA                              //
//                                       DETHECHECKSDONT                               //
//                                        FADETHECHECKS                                //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract FADE is ERC721Creator {
    constructor() ERC721Creator("Don't Fade the Checks", "FADE") {}
}