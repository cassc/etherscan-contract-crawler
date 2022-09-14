// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Institute of Non Fungible Tokenology
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    WARNING: These substances have a high potential to cause harm, even if you are      //
//    only exposed to a small amount of them. You must take special precautions           //
//    if you are manufacturing, handling or using these tokens.                           //
//    They should be available only to specialised or authorised users                    //
//    who have the skills necessary to handle them safely.                                //
//    These products are not usually found in blockchain but are often found on farms.    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract INFT is ERC721Creator {
    constructor() ERC721Creator("Institute of Non Fungible Tokenology", "INFT") {}
}