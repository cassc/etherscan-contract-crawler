// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mandala Girl NFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//          JNgJ     (JgF     .JJJ.     dN&J  .JJJ,   (+ggg-.        .JJ,     .JJJJ          .JJ,              ..JgggJ.   (JJJ,   .Jgggg-.    (JJJ.             //
//           MMMb   -MMM      (MMMb      MMMb  MM#    MM#"TWMN,     .MMMN.     dMM~         .MMMM,           .dMMY""""`    MMM    (MMY"TMMb   .MMF              //
//           MMMMp .MMMM     .MM(MM,     MMMMb dM#    MMF   dMM.    MM]dMb     dMM_         JMFdMN           dMM!.J....\   MMM    (MM~ .MM#   .MMF              //
//           MMFWMJM#(MM     MMF dMN     MMFTMRdM#    MMF   .MM!   -M# ,MM,    dMM_        .MM`.MM]          MMN .MMMM#    MMM    (MMMMMM"    .MMF              //
//           MMF MMM`(MM    -MMMMMMMb    MMF TMMM#    MMF  .dM#   .MMMMMMMN    dMM_   .   .MMMMMMMN.         JMMe   MM#    MMM    (MM~ WMN.   .MMF    .         //
//          .MMb     (MM,  .MMF   dMM,  .MMb  ?MMN    MMMNMMMD    dM#   ,MMb   dMMMMMMN   JMM`  .MMb          ?MMMMMMM#   .MMM,   (MM;  MMb   .MMMMMMM]         //
//                                              _73    `~!`                   ,"!    _"                           ~!`                         "^`    ?^         //
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ......................................................................................................................................................    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MANDALG is ERC721Creator {
    constructor() ERC721Creator("Mandala Girl NFT", "MANDALG") {}
}