// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MURICARDS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    FROME THE MEEPLE OF MURICA FOR THE MEEPLE OF MURICA.    //
//    MAKE MURICA GREAT AGAIN!                                //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract MC is ERC1155Creator {
    constructor() ERC1155Creator("MURICARDS", "MC") {}
}