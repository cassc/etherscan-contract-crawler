// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Contract Reader Tabs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    ContractReader.io Tabs Feature Release NFT    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract CRTabs is ERC721Creator {
    constructor() ERC721Creator("Contract Reader Tabs", "CRTabs") {}
}