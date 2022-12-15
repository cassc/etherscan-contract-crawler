// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bakemono Zukushi by Nao Yoshihara
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//                        //
//    ][\][ //-\ [[]]     //
//                        //
//                        //
//                        //
////////////////////////////


contract BZNY is ERC721Creator {
    constructor() ERC721Creator("Bakemono Zukushi by Nao Yoshihara", "BZNY") {}
}