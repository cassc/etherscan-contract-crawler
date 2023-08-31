// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BulletProof Heart
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//      /\  /\      //
//     /  \/  \     //
//     \      /     //
//      \    /      //
//       \  /       //
//        \/        //
//                  //
//                  //
//                  //
//////////////////////


contract BulletProofHeart is ERC721Creator {
    constructor() ERC721Creator("BulletProof Heart", "BulletProofHeart") {}
}