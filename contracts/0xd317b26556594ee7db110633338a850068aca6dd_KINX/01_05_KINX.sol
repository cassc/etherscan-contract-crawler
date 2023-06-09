// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kinx
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//     __   .__                   //
//    |  | _|__| ____ ___  ___    //
//    |  |/ /  |/    \\  \/  /    //
//    |    <|  |   |  \>    <     //
//    |__|_ \__|___|  /__/\_ \    //
//         \/       \/      \/    //
//                                //
//                                //
//                                //
////////////////////////////////////


contract KINX is ERC721Creator {
    constructor() ERC721Creator("Kinx", "KINX") {}
}