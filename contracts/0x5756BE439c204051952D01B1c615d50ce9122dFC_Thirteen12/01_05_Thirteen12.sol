// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Platin GDMD Aerosol CAN ( open edition )
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//    ___________.__    .__         __                       ____________      //
//    \__    ___/|  |__ |__|_______/  |_  ____   ____   ____/_   \_____  \     //
//      |    |   |  |  \|  \_  __ \   __\/ __ \_/ __ \ /    \|   |/  ____/     //
//      |    |   |   Y  \  ||  | \/|  | \  ___/\  ___/|   |  \   /       \     //
//      |____|   |___|  /__||__|   |__|  \___  >\___  >___|  /___\_______ \    //
//                    \/                     \/     \/     \/            \/    //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract Thirteen12 is ERC1155Creator {
    constructor() ERC1155Creator("Platin GDMD Aerosol CAN ( open edition )", "Thirteen12") {}
}