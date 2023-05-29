// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IAM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    iamintriguingart    //
//                        //
//                        //
////////////////////////////


contract IAM is ERC721Creator {
    constructor() ERC721Creator("IAM", "IAM") {}
}