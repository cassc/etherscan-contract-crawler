// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Max Petretta
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//                                        __            __  __              __  __      //
//       ____ ___  ____ __  ______  ___  / /_________  / /_/ /_____ _ ___  / /_/ /_     //
//      / __ `__ \/ __ `/ \/ / __ \/ _ \/ __/ ___/ _ \/ __/ __/ __ `// _ \/ __/ __ \    //
//     / / / / / / /_/ /\  \/ /_/ /  __/ /_/ /  /  __/ /_/ /_/ /_/ //  __/ /_/ / / /    //
//    /_/ /_/ /_/\__,_/_/\_/ .___/\___/\__/_/   \___/\__/\__/\__,_(_)___/\__/_/ /_/     //
//                        /_/                                                           //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract MP is ERC721Creator {
    constructor() ERC721Creator("Max Petretta", "MP") {}
}