// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pnizo collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    　　　　　　 　　終       //
//    　　　　　　 制作・著作     //
//    　　　　　　 ━━━━━     //
//    　　　　　　 　pnizo    //
//                     //
//                     //
/////////////////////////


contract PNIZO is ERC721Creator {
    constructor() ERC721Creator("pnizo collection", "PNIZO") {}
}