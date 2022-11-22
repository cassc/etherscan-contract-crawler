// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test feesn mainnet
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//         .__       //
//      ____ |__|    //
//     /    \|  |    //
//    |   |  \  |    //
//    |___|  /__|    //
//         \/        //
//                   //
//                   //
///////////////////////


contract ts is ERC721Creator {
    constructor() ERC721Creator("Test feesn mainnet", "ts") {}
}