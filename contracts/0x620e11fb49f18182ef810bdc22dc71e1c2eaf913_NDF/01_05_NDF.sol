// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nyan DeathFlower
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//        __      _  ______   _________      //
//       /  \    / )(_  __ \ (_   _____)     //
//      / /\ \  / /   ) ) \ \  ) (___        //
//      ) ) ) ) ) )  ( (   ) )(   ___)       //
//     ( ( ( ( ( (    ) )  ) ) ) (           //
//     / /  \ \/ /   / /__/ / (   )          //
//    (_/    \__/   (______/   \_/           //
//                                           //
//    NDF.MEME By KhooKG                     //
//                                           //
//                                           //
///////////////////////////////////////////////


contract NDF is ERC1155Creator {
    constructor() ERC1155Creator("Nyan DeathFlower", "NDF") {}
}