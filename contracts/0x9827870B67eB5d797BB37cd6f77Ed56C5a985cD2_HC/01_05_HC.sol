// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    /////////                             //
//                                          //
//    The official HC 1/1 NFT contract.     //
//                                          //
//    /////////                             //
//                                          //
//                                          //
//////////////////////////////////////////////


contract HC is ERC721Creator {
    constructor() ERC721Creator("HC", "HC") {}
}