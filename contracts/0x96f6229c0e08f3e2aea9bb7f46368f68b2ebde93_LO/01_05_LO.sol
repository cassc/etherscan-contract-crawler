// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life Outdoors
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//       __________               .__       //
//        |__\_____  \  ______ _____|__|    //
//        |  | _(__  < /  ___//  ___/  |    //
//        |  |/       \\___ \ \___ \|  |    //
//    /\__|  /______  /____  >____  >__|    //
//    \______|      \/     \/     \/        //
//                                          //
//                                          //
//////////////////////////////////////////////


contract LO is ERC721Creator {
    constructor() ERC721Creator("Life Outdoors", "LO") {}
}