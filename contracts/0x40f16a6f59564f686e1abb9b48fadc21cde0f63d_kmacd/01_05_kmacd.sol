// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KateMacDonald
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                           ,,         //
//    `7MM                                                 `7MM         //
//      MM                                                   MM         //
//      MM  ,MP'   `7MMpMMMb.pMMMb.   ,6"Yb.  ,p6"bo    ,M""bMM         //
//      MM ;Y        MM    MM    MM  8)   MM 6M'  OO  ,AP    MM         //
//      MM;Mm        MM    MM    MM   ,pm9MM 8M       8MI    MM         //
//      MM `Mb. ,,   MM    MM    MM  8M   MM YM.    , `Mb    MM  ,,     //
//    .JMML. YA.db .JMML  JMML  JMML.`Moo9^Yo.YMbmd'   `Wbmd"MML.db     //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract kmacd is ERC721Creator {
    constructor() ERC721Creator("KateMacDonald", "kmacd") {}
}