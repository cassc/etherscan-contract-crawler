// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VSP Playoff Football Competition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    VSP Football Playoff Competition    //
//                                        //
//                                        //
////////////////////////////////////////////


contract VSPFB is ERC1155Creator {
    constructor() ERC1155Creator("VSP Playoff Football Competition", "VSPFB") {}
}