// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ☕️ GM GENERETOR ☕️
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
//                              / /           /    /                   //
//     ___  _ _       ___  ___ ( (  ___  ___ (___    ___  ___          //
//    |   )| | )     |    |   )| | |___)|    |    | |   )|   )         //
//    |__/ |  /      |__  |__/ | | |__  |__  |__  | |__/ |  /          //
//    __/                                                              //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract GMG is ERC1155Creator {
    constructor() ERC1155Creator(unicode"☕️ GM GENERETOR ☕️", "GMG") {}
}