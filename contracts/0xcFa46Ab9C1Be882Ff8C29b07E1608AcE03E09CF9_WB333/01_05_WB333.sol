// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Water body
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//    ________ ________ ____________________________ ________    ________________________________________.___________      _____  ________  ________ ________ ________      //
//    \_____  \\_____  \\_____  \______   \______   \\_____  \  /   _____/\______   \_   _____/\______   \   \______ \    /  _  \ \______ \ \_____  \\_____  \\_____  \     //
//      _(__  <  _(__  <  _(__  <|     ___/|       _/ /   |   \ \_____  \  |     ___/|    __)_  |       _/   ||    |  \  /  /_\  \ |    |  \  _(__  <  _(__  <  _(__  <     //
//     /       \/       \/       \    |    |    |   \/    |    \/        \ |    |    |        \ |    |   \   ||    `   \/    |    \|    `   \/       \/       \/       \    //
//    /______  /______  /______  /____|    |____|_  /\_______  /_______  / |____|   /_______  / |____|_  /___/_______  /\____|__  /_______  /______  /______  /______  /    //
//           \/       \/       \/                 \/         \/        \/                   \/         \/            \/         \/        \/       \/       \/       \/     //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WB333 is ERC721Creator {
    constructor() ERC721Creator("Water body", "WB333") {}
}