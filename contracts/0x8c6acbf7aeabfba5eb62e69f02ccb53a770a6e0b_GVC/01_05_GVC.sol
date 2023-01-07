// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gary Vaynerchonk
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    Gary Vaynerchonk devours ETH. Feed Gary. Gary must chonk.     //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract GVC is ERC721Creator {
    constructor() ERC721Creator("Gary Vaynerchonk", "GVC") {}
}