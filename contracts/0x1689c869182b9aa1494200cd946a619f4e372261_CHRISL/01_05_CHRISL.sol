// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ChrisL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                                                                   //
//                  ,,                   ,,                          //
//      .g8"""bgd `7MM                   db          `7MMF'          //
//    .dP'     `M   MM                                 MM            //
//    dM'       `   MMpMMMb.  `7Mb,od8 `7MM  ,pP"Ybd   MM            //
//    MM            MM    MM    MM' "'   MM  8I   `"   MM            //
//    MM.           MM    MM    MM       MM  `YMMMa.   MM      ,     //
//    `Mb.     ,'   MM    MM    MM       MM  L.   I8   MM     ,M     //
//      `"bmmmd'  .JMML  JMML..JMML.   .JMML.M9mmmP' .JMMmmmmMMM     //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract CHRISL is ERC721Creator {
    constructor() ERC721Creator("ChrisL", "CHRISL") {}
}