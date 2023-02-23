// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Custom Abstract PFP
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    // Custom Abstract PFPs by Hemily, for you //    //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract Hemspfp is ERC721Creator {
    constructor() ERC721Creator("Custom Abstract PFP", "Hemspfp") {}
}