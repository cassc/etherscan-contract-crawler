// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: onchaingf
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    ///onchain-gf\\\    //
//    \\\onchain-gf///    //
//    ///onchain-gf\\\    //
//    \\\onchain-gf///    //
//    ///onchain-gf\\\    //
//    \\\onchain-gf///    //
//    ///onchain-gf\\\    //
//    \\\onchain-gf///    //
//                        //
//                        //
////////////////////////////


contract onchaingf is ERC721Creator {
    constructor() ERC721Creator("onchaingf", "onchaingf") {}
}