// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: buzz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//                                                                                         //
//    ___.                        .__  .__       .__     __         .__                    //
//    \_ |__  __ _________________|  | |__| ____ |  |___/  |_  ____ |__| ____    ____      //
//     | __ \|  |  \___   /\___   /  | |  |/ ___\|  |  \   __\/    \|  |/    \  / ___\     //
//     | \_\ \  |  //    /  /    /|  |_|  / /_/  >   Y  \  | |   |  \  |   |  \/ /_/  >    //
//     |___  /____//_____ \/_____ \____/__\___  /|___|  /__| |___|  /__|___|  /\___  /     //
//         \/            \/      \/      /_____/      \/          \/        \//_____/      //
//                                                                                         //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract buzz is ERC721Creator {
    constructor() ERC721Creator("buzz", "buzz") {}
}