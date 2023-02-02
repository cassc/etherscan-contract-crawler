// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WhereIDraw
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//    db   d8b   db db   db d88888b d8888b. d88888b d888888b d8888b. d8888b.  .d8b.  db   d8b   db     //
//    88   I8I   88 88   88 88'     88  `8D 88'       `88'   88  `8D 88  `8D d8' `8b 88   I8I   88     //
//    88   I8I   88 88ooo88 88ooooo 88oobY' 88ooooo    88    88   88 88oobY' 88ooo88 88   I8I   88     //
//    Y8   I8I   88 88~~~88 88~~~~~ 88`8b   88~~~~~    88    88   88 88`8b   88~~~88 Y8   I8I   88     //
//    `8b d8'8b d8' 88   88 88.     88 `88. 88.       .88.   88  .8D 88 `88. 88   88 `8b d8'8b d8'     //
//     `8b8' `8d8'  YP   YP Y88888P 88   YD Y88888P Y888888P Y8888D' 88   YD YP   YP  `8b8' `8d8'      //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WID23 is ERC721Creator {
    constructor() ERC721Creator("WhereIDraw", "WID23") {}
}