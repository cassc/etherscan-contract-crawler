// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoDegen
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    full time degen     //
//    crypto degen art    //
//                        //
//                        //
//                        //
////////////////////////////


contract CDGN is ERC1155Creator {
    constructor() ERC1155Creator("CryptoDegen", "CDGN") {}
}