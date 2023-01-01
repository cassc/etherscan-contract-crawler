// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bonne Année 2023
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Bonne Année 2023    //
//                        //
//                        //
////////////////////////////


contract BonneAnnee2023 is ERC721Creator {
    constructor() ERC721Creator(unicode"Bonne Année 2023", "BonneAnnee2023") {}
}