// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Press Release Pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    Gokhshtein Media Press Release NFTs. Only good for one time use.     //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract GPR is ERC721Creator {
    constructor() ERC721Creator("Press Release Pass", "GPR") {}
}