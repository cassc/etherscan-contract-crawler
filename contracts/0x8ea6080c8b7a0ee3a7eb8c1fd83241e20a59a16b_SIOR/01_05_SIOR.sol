// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TOSIOR
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    ¯¯¯¯¯|° /¯¯¯¯¯\ /¯¯¯¯¯/ '    O     /¯¯¯¯¯\ |¯¯¯¯\                    //
//    |         | |     x    |'\ __¯¯¯\' |¯¯¯¯| |     x    |'|   x  <|'    //
//     ¯|__|¯   \_____/ /______/||____|  \_____/ |__|\__\                  //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract SIOR is ERC721Creator {
    constructor() ERC721Creator("TOSIOR", "SIOR") {}
}