// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MonsieuRabbit Genesis Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//            🐰  🐰        //
//          🐰🐰  🐰🐰      //
//        🐰🐰🐰  🐰🐰🐰    //
//          🐰🐰  🐰🐰      //
//            🐰  🐰        //
//                          //
//                          //
//////////////////////////////


contract MRGC is ERC1155Creator {
    constructor() ERC1155Creator("MonsieuRabbit Genesis Collection", "MRGC") {}
}