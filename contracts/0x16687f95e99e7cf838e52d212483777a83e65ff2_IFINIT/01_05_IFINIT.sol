// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Infinitereflections
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//    .__        _____.__       .__  __              //
//    |__| _____/ ____\__| ____ |__|/  |_  ____      //
//    |  |/    \   __\|  |/    \|  \   __\/ __ \     //
//    |  |   |  \  |  |  |   |  \  ||  | \  ___/     //
//    |__|___|  /__|  |__|___|  /__||__|  \___  >    //
//            \/              \/              \/     //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract IFINIT is ERC1155Creator {
    constructor() ERC1155Creator("Infinitereflections", "IFINIT") {}
}