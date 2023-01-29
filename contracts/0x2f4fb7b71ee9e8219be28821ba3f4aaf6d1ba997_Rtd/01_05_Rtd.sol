// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ROAST3D
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXROAST3DXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract Rtd is ERC1155Creator {
    constructor() ERC1155Creator("ROAST3D", "Rtd") {}
}