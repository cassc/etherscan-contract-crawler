// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: windshitheavy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                        .__            //
//       ____   ____   ____   ____   _____|__| ______    //
//      / ___\_/ __ \ /    \_/ __ \ /  ___/  |/  ___/    //
//     / /_/  >  ___/|   |  \  ___/ \___ \|  |\___ \     //
//     \___  / \___  >___|  /\___  >____  >__/____  >    //
//    /_____/      \/     \/     \/     \/        \/     //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract whh is ERC1155Creator {
    constructor() ERC1155Creator("windshitheavy", "whh") {}
}