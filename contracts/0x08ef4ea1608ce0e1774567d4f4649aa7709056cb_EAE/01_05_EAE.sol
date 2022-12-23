// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eren ARIK
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    Eren ARIK Manifold editions    //
//                                   //
//                                   //
///////////////////////////////////////


contract EAE is ERC1155Creator {
    constructor() ERC1155Creator("Eren ARIK", "EAE") {}
}