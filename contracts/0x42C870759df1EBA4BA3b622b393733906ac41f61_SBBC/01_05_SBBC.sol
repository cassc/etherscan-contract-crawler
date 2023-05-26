// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SBB Commissions Contract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//      _____________________________     //
//     /   _____/\______   \______   \    //
//     \_____  \  |    |  _/|    |  _/    //
//     /        \ |    |   \|    |   \    //
//    /_______  / |______  /|______  /    //
//            \/         \/        \/     //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract SBBC is ERC721Creator {
    constructor() ERC721Creator("SBB Commissions Contract", "SBBC") {}
}