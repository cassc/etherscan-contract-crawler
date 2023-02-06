// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Juicechecks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    This juicebox may or may not be notable.    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract JCHKS is ERC1155Creator {
    constructor() ERC1155Creator("Juicechecks", "JCHKS") {}
}