// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Death to Coco
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//     ____  _____  ____   __    __  __  ____  _  _  ____     //
//    (  _ \(  _  )(  _ \ /__\  (  \/  )(_  _)( \( )( ___)    //
//     )(_) ))(_)(  )___//(__)\  )    (  _)(_  )  (  )__)     //
//    (____/(_____)(__) (__)(__)(_/\/\_)(____)(_)\_)(____     //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract COCO is ERC1155Creator {
    constructor() ERC1155Creator("Death to Coco", "COCO") {}
}