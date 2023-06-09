// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TheBenMeadows
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    TheBenMeadows    //
//                     //
//                     //
/////////////////////////


contract TBM is ERC721Creator {
    constructor() ERC721Creator("TheBenMeadows", "TBM") {}
}