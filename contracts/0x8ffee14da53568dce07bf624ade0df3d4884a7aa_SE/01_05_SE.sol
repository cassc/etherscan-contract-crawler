// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Storm editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    Official storm editions contract    //
//                                        //
//                                        //
////////////////////////////////////////////


contract SE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}