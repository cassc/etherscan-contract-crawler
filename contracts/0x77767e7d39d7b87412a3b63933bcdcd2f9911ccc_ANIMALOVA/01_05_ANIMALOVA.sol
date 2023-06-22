// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Animalova
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//      _       ___       _       _        _      //
//     /_) )\ )  )  )\/) /_) )   / ) \  / /_)     //
//    / / (  ( _(_ (  ( / / (__ (_/   \/ / /      //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract ANIMALOVA is ERC721Creator {
    constructor() ERC721Creator("Animalova", "ANIMALOVA") {}
}