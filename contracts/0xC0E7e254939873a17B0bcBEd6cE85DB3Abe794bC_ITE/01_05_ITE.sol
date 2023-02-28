// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In the embrace
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    ___________       .__                                //
//    \__    ___/_  _  _|__| ____   ____   ____ ___.__.    //
//      |    |  \ \/ \/ /  |/    \ /    \_/ __ <   |  |    //
//      |    |   \     /|  |   |  \   |  \  ___/\___  |    //
//      |____|    \/\_/ |__|___|  /___|  /\___  > ____|    //
//                              \/     \/     \/\/         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract ITE is ERC1155Creator {
    constructor() ERC1155Creator("In the embrace", "ITE") {}
}