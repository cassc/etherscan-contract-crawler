// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TitVagsaic
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    TitVagsaic    //
//                  //
//                  //
//////////////////////


contract TitVagsaic is ERC721Creator {
    constructor() ERC721Creator("TitVagsaic", "TitVagsaic") {}
}