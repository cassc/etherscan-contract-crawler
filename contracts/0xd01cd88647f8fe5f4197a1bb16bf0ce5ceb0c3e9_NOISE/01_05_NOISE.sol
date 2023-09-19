// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NO ONE NOISE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//    My art is an exploration of humans' sensuality, in an ironic, sarcastic, dark tone.    //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract NOISE is ERC1155Creator {
    constructor() ERC1155Creator("NO ONE NOISE", "NOISE") {}
}