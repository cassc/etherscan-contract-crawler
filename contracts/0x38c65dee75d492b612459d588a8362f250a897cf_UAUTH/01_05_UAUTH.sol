// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UNAUTHORIZED
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\    //
//    XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX    //
//    x _   _ _   _   ___  _   _ _____ _   _ ___________ _____ ______ ___________ x    //
//    X| | | | \ | | / _ \| | | |_   _| | | |  _  | ___ \_   _|___  /|  ___|  _  \X    //
//    x| | | |  \| |/ /_\ \ | | | | | | |_| | | | | |_/ / | |    / / | |__ | | | |x    //
//    X| | | | . ` ||  _  | | | | | | |  _  | | | |    /  | |   / /  |  __|| | | |X    //
//    x| |_| | |\  || | | | |_| | | | | | | \ \_/ / |\ \ _| |_./ /___| |___| |/ / x    //
//    X \___/\_| \_/\_| |_/\___/  \_/ \_| |_/\___/\_| \_|\___/\_____/\____/|___/  X    //
//    x                                                                           x    //
//    XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX    //
//    /////////////////////////////////////////////////////////////////////////////    //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract UAUTH is ERC721Creator {
    constructor() ERC721Creator("UNAUTHORIZED", "UAUTH") {}
}