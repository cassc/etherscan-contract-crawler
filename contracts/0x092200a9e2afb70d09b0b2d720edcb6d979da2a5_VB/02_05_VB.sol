// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PFP VB
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    Unique PFP on mainnet Ethereum by Vinícius Bedum    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract VB is ERC721Creator {
    constructor() ERC721Creator("PFP VB", "VB") {}
}