// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Maniacs AI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Ⓒⓡⓨⓟⓣⓘⓒⓜⓐⓝⓘⓐⓒ    //
//                     //
//                     //
/////////////////////////


contract MAI is ERC721Creator {
    constructor() ERC721Creator("Maniacs AI", "MAI") {}
}