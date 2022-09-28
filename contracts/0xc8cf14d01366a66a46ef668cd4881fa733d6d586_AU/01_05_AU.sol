// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arweave Uploader
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Arweave Uploader    //
//                        //
//                        //
////////////////////////////


contract AU is ERC721Creator {
    constructor() ERC721Creator("Arweave Uploader", "AU") {}
}