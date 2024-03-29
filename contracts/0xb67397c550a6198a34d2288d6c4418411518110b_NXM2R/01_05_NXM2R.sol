// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Next Memory
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//                                                                                               //
//     _______                     __       _____                                                //
//     \      \    ____  ___  ____/  |_    /     \    ____    _____    ____  _______  ___.__.    //
//     /   |   \ _/ __ \ \  \/  /\   __\  /  \ /  \ _/ __ \  /     \  /  _ \ \_  __ \<   |  |    //
//    /    |    \\  ___/  >    <  |  |   /    Y    \\  ___/ |  Y Y  \(  <_> ) |  | \/ \___  |    //
//    \____|__  / \___  >/__/\_ \ |__|   \____|__  / \___  >|__|_|  / \____/  |__|    / ____|    //
//    ___.    \/      \/__.    \/_               \/      \/       \/ .__              \/         //
//    \_ |__   ___.__. \_ |__  |  | _____  __  ____  ___  ___  ____  |  |                        //
//     | __ \ <   |  |  | __ \ |  |/ /\  \/ / /  _ \ \  \/  /_/ __ \ |  |                        //
//     | \_\ \ \___  |  | \_\ \|    <  \   / (  <_> ) >    < \  ___/ |  |__                      //
//     |___  / / ____|  |___  /|__|_ \  \_/   \____/ /__/\_ \ \___  >|____/                      //
//         \/  \/           \/      \/                     \/     \/                             //
//                                                                                               //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract NXM2R is ERC721Creator {
    constructor() ERC721Creator("Next Memory", "NXM2R") {}
}