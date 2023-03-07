// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SmugbunnyCGAnimation
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Smugbunny CG Animation    //
//                              //
//                              //
//////////////////////////////////


contract SCG is ERC1155Creator {
    constructor() ERC1155Creator("SmugbunnyCGAnimation", "SCG") {}
}