// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Token Compensation Paradox
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    Experiments by Kairon and Eliot    //
//                                       //
//                                       //
///////////////////////////////////////////


contract TCP is ERC721Creator {
    constructor() ERC721Creator("The Token Compensation Paradox", "TCP") {}
}