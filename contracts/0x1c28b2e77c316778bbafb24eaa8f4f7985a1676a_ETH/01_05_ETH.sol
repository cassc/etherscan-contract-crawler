// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nicholas' NFTs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//      ／l、       //
//    （ﾟ､ ｡７      //
//     l、ﾞ~ヽ      //
//    じしf_, )ノ    //
//                //
//                //
////////////////////


contract ETH is ERC721Creator {
    constructor() ERC721Creator("Nicholas' NFTs", "ETH") {}
}