// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: utopic soul
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                                                         //
//          /              /                          /    //
//         (___  ___  ___    ___       ___  ___      (     //
//    |   )|    |   )|   )| |         |___ |   )|   )|     //
//    |__/ |__  |__/ |__/ | |__        __/ |__/ |__/ |     //
//                   |                                     //
//                                                         //
//                                                         //
//    by darknoov                                          //
//    orginal size 5x5                                     //
//    create date 10.21                                    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract usoul is ERC721Creator {
    constructor() ERC721Creator("utopic soul", "usoul") {}
}