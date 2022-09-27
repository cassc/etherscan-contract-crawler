// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SOULTREES by Louis Iruela
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//     ███████  ██████  ██    ██ ██      ████████ ██████  ███████ ███████ ███████           //
//    ██      ██    ██ ██    ██ ██         ██    ██   ██ ██      ██      ██                 //
//    ███████ ██    ██ ██    ██ ██         ██    ██████  █████   █████   ███████            //
//         ██ ██    ██ ██    ██ ██         ██    ██   ██ ██      ██           ██            //
//    ███████  ██████   ██████  ███████    ██    ██   ██ ███████ ███████ ███████            //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//    The holder of this NFT is free to display the associated file privately               //
//    and publicly, including in commercial and non-commercial settings,                    //
//    and in groups with an unlimited number of participants.                               //
//    The license includes unlimited use and displays in virtual or physical galleries,     //
//    documentaries, and essays by the NFT holder.                                          //
//    Provides no rights to create commercial merchandise, commercial distribution,         //
//    or derivative works. Creator retains full commercial rights,                          //
//    including the right to produce and sell physical prints.                              //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract ST is ERC721Creator {
    constructor() ERC721Creator("SOULTREES by Louis Iruela", "ST") {}
}