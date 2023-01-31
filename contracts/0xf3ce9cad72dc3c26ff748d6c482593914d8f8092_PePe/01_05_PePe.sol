// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KING OPEPEN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    Art By 0xnftshustle                   //
//                                          //
//    Homage to Opepen from @jackbutcher    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract PePe is ERC1155Creator {
    constructor() ERC1155Creator("KING OPEPEN", "PePe") {}
}