// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Human Experiment
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    The Human Experiment    //
//                            //
//                            //
////////////////////////////////


contract THE is ERC1155Creator {
    constructor() ERC1155Creator("The Human Experiment", "THE") {}
}