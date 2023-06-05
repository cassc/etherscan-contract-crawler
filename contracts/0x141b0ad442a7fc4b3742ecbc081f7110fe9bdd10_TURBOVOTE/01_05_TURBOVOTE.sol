// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Turbo Toad Prop House Community Voting Token
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//                                _    _                                //
//                              ⌐(🅃)-(🅃)                              //
//                             __(   "   )__                            //
//                            / _/'-----'\_ \                           //
//                         ___\\ \\     // //___                        //
//                         >____)/_\---/_\(____<                        //
//                                                                      //
//      __              ___.              __                    .___    //
//    _/  |_ __ ________\_ |__   ____   _/  |_  _________     __| _/    //
//    \   __\  |  \_  __ \ __ \ /  _ \  \   __\/  _ \__  \   / __ |     //
//     |  | |  |  /|  | \/ \_\ (  <_> )  |  | (  <_> ) __ \_/ /_/ |     //
//     |__| |____/ |__|  |___  /\____/   |__|  \____(____  /\____ |     //
//                           \/                          \/      \/     //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract TURBOVOTE is ERC721Creator {
    constructor() ERC721Creator("Turbo Toad Prop House Community Voting Token", "TURBOVOTE") {}
}