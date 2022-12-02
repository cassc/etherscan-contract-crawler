// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: For the love of GMᵍᵐ
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    For the love of GMᵍᵐ    //
//                            //
//                            //
////////////////////////////////


contract RGM is ERC1155Creator {
    constructor() ERC1155Creator(unicode"For the love of GMᵍᵐ", "RGM") {}
}