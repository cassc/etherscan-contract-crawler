// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Scott Beale Photography
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//       _____            __  __     ____             __       //
//      / ___/_________  / /_/ /_   / __ )___  ____ _/ /__     //
//      \__ \/ ___/ __ \/ __/ __/  / __  / _ \/ __ `/ / _ \    //
//     ___/ / /__/ /_/ / /_/ /_   / /_/ /  __/ /_/ / /  __/    //
//    /____/\___/\____/\__/\__/  /_____/\___/\__,_/_/\___/     //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract PHOTO is ERC1155Creator {
    constructor() ERC1155Creator("Scott Beale Photography", "PHOTO") {}
}