// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Maxwell 1 of 1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                                                                   ,,    ,,      //
//    `7MMM.     ,MMF'                                             `7MM  `7MM      //
//      MMMb    dPMM                                                 MM    MM      //
//      M YM   ,M MM   ,6"Yb.  `7M'   `MF'`7M'    ,A    `MF'.gP"Ya   MM    MM      //
//      M  Mb  M' MM  8)   MM    `VA ,V'    VA   ,VAA   ,V ,M'   Yb  MM    MM      //
//      M  YM.P'  MM   ,pm9MM      XMX       VA ,V  VA ,V  8M""""""  MM    MM      //
//      M  `YM'   MM  8M   MM    ,V' VA.      VVV    VVV   YM.    ,  MM    MM      //
//    .JML. `'  .JMML.`Moo9^Yo..AM.   .MA.     W      W     `Mbmmd'.JMML..JMML.    //
//                                                                                 //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract Mxwll is ERC721Creator {
    constructor() ERC721Creator("Maxwell 1 of 1s", "Mxwll") {}
}