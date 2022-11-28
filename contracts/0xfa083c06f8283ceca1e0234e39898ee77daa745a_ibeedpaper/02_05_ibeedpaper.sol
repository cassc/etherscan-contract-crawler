// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: iBEED Paper
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//    Space to register iBEED public papers on blockchain. (Litepaper, Whitepaper)            //
//                                                                                            //
//    Whenever we have new updates on whitepaper v1, v2 and so on it will be created here.    //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract ibeedpaper is ERC721Creator {
    constructor() ERC721Creator("iBEED Paper", "ibeedpaper") {}
}