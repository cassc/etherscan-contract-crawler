// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sketchez
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//     SSSSS  kk            tt           hh                       //
//    SS      kk  kk   eee  tt      cccc hh        eee  zzzzz     //
//     SSSSS  kkkkk  ee   e tttt  cc     hhhhhh  ee   e   zz      //
//         SS kk kk  eeeee  tt    cc     hh   hh eeeee   zz       //
//     SSSSS  kk  kk  eeeee  tttt  ccccc hh   hh  eeeee zzzzz     //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract SKETCH is ERC1155Creator {
    constructor() ERC1155Creator("Sketchez", "SKETCH") {}
}