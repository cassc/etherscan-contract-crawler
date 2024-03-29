// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ELECTRIC
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//         ____.________  ________________.___. _________  ________   ____ ___  ________  ___ ___      //
//        |    |\_____  \ \_   _____/\__  |   | \_   ___ \ \_____  \ |    |   \/  _____/ /   |   \     //
//        |    | /   |   \ |    __)_  /   |   | /    \  \/  /   |   \|    |   /   \  ___/    ~    \    //
//    /\__|    |/    |    \|        \ \____   | \     \____/    |    \    |  /\    \_\  \        /     //
//    \________|\_______  /_______  / / ______|  \______  /\_______  /______/  \______  /\___|_  /     //
//                      \/        \/  \/                \/         \/                 \/       \/      //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ELECT is ERC1155Creator {
    constructor() ERC1155Creator("ELECTRIC", "ELECT") {}
}