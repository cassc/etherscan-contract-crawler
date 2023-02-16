// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shrouded Sculptures by Simon Roberts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    SHROUDED SCULPTURES BY SIMON ROBERTS    //
//    IMAGES © SIMON ROBERTS                  //
//    ALL RIGHTS RESERVED                     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract SCULPT is ERC721Creator {
    constructor() ERC721Creator("Shrouded Sculptures by Simon Roberts", "SCULPT") {}
}