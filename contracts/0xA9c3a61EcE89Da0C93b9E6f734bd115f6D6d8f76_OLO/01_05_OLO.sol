// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OLO
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    .-.-. .-.-. .-.-.      //
//    '. O )'. L )'. O )     //
//      ).'   ).'   ).'      //
//                           //
//                           //
//                           //
///////////////////////////////


contract OLO is ERC1155Creator {
    constructor() ERC1155Creator("OLO", "OLO") {}
}