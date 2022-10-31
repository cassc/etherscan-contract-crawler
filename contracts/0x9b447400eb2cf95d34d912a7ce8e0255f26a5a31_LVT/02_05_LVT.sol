// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dream Lake
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//    LL             tt     '        VV     VV iii                   TTTTTTT hh      iii           //
//    LL        eee  tt    '''  sss  VV     VV       eee  ww      ww   TTT   hh           sss      //
//    LL      ee   e tttt  ''  s      VV   VV  iii ee   e ww      ww   TTT   hhhhhh  iii s         //
//    LL      eeeee  tt         sss    VV VV   iii eeeee   ww ww ww    TTT   hh   hh iii  sss      //
//    LLLLLLL  eeeee  tttt         s    VVV    iii  eeeee   ww  ww     TTT   hh   hh iii     s     //
//                              sss                                                       sss      //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////


contract LVT is ERC721Creator {
    constructor() ERC721Creator("Dream Lake", "LVT") {}
}