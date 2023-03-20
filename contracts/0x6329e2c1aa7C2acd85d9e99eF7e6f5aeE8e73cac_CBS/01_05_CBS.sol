// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Colorblind Studios
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//     CCCCC         lll               bb      lll iii              dd     //
//    CC    C  oooo  lll  oooo  rr rr  bb      lll     nn nnn       dd     //
//    CC      oo  oo lll oo  oo rrr  r bbbbbb  lll iii nnn  nn  dddddd     //
//    CC    C oo  oo lll oo  oo rr     bb   bb lll iii nn   nn dd   dd     //
//     CCCCC   oooo  lll  oooo  rr     bbbbbb  lll iii nn   nn  dddddd     //
//                                                                         //
//              SSSSS  tt                 dd iii                           //
//             SS      tt    uu   uu      dd      oooo   sss               //
//              SSSSS  tttt  uu   uu  dddddd iii oo  oo s                  //
//                  SS tt    uu   uu dd   dd iii oo  oo  sss               //
//              SSSSS   tttt  uuuu u  dddddd iii  oooo      s              //
//                                                       sss               //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract CBS is ERC1155Creator {
    constructor() ERC1155Creator("Colorblind Studios", "CBS") {}
}