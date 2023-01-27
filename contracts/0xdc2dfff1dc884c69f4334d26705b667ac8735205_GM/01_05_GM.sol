// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Golden GM
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//      ## ##   ##   ##      //
//    ##   ##   ## ##        //
//    ##       # ### #       //
//    ##  ###  ## # ##       //
//    ##   ##  ##   ##       //
//    ##   ##  ##   ##       //
//     ## ##   ##   ##       //
//                           //
//                           //
//                           //
//                           //
///////////////////////////////


contract GM is ERC1155Creator {
    constructor() ERC1155Creator("Golden GM", "GM") {}
}