// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memo Akten
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                        __           //
//       ____ ___  ___  ____ ___  ____   / /__   __    //
//      / __ `__ \/ _ \/ __ `__ \/ __ \ / __/ | / /    //
//     / / / / / /  __/ / / / / / /_/ // /_ | |/ /     //
//    /_/ /_/ /_/\___/_/ /_/ /_/\____(_)__/ |___/      //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract MSA is ERC721Creator {
    constructor() ERC721Creator("Memo Akten", "MSA") {}
}