// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tea with AI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//    TTTTTTT                              iii tt    hh           AAA   IIIII     //
//      TTT     eee    aa aa    ww      ww     tt    hh          AAAAA   III      //
//      TTT   ee   e  aa aaa    ww      ww iii tttt  hhhhhh     AA   AA  III      //
//      TTT   eeeee  aa  aaa     ww ww ww  iii tt    hh   hh    AAAAAAA  III      //
//      TTT    eeeee  aaa aa      ww  ww   iii  tttt hh   hh    AA   AA IIIII     //
//                                                                                //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract TAI is ERC721Creator {
    constructor() ERC721Creator("Tea with AI", "TAI") {}
}