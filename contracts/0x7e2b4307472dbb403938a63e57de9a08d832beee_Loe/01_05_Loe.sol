// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Loechii
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    .____                        .__    .__.__     //
//    |    |    ____   ____   ____ |  |__ |__|__|    //
//    |    |   /  _ \_/ __ \_/ ___\|  |  \|  |  |    //
//    |    |__(  <_> )  ___/\  \___|   Y  \  |  |    //
//    |_______ \____/ \___  >\___  >___|  /__|__|    //
//            \/          \/     \/     \/           //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract Loe is ERC1155Creator {
    constructor() ERC1155Creator("Loechii", "Loe") {}
}