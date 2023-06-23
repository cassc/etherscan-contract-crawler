// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bucket
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                                                                                                                                           //
//    Unlock the secrets held within the ethereal depths of the Bucket's NFT collection, where hidden treasures and enigmatic tales await    //
//                                                                                                                                           //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BUCKET is ERC721Creator {
    constructor() ERC721Creator("Bucket", "BUCKET") {}
}