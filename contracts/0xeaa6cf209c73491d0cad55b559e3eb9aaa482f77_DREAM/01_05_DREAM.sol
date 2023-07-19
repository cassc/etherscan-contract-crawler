// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3D Abstract Arts
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                   //
//    My Name is Dream, am a Digital Abstract Artist. Have being an Artist for over 12 years and each time Create it's just like Creating an happiness for myself because my artwork are engraved in my soul and it's connected with my emotions and my feelings.    //
//                                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DREAM is ERC1155Creator {
    constructor() ERC1155Creator("3D Abstract Arts", "DREAM") {}
}