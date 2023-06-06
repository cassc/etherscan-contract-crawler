// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Snorkelz Airdrop
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    SNORKELZ    //
//    AIRDROP     //
//    DOUBLE      //
//    SHEESH      //
//                //
//                //
////////////////////


contract SNRKDRP is ERC1155Creator {
    constructor() ERC1155Creator("Snorkelz Airdrop", "SNRKDRP") {}
}