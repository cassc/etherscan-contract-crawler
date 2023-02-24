// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FOUNDATION COLLECTOR AIRDROP
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//         _    ___ ____  ____  ____   ___  ____      //
//        / \  |_ _|  _ \|  _ \|  _ \ / _ \|  _ \     //
//       / _ \  | || |_) | | | | |_) | | | | |_) |    //
//      / ___ \ | ||  _ <| |_| |  _ <| |_| |  __/     //
//     /_/   \_\___|_| \_\____/|_| \_\\___/|_|        //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract AIRDROP is ERC1155Creator {
    constructor() ERC1155Creator("FOUNDATION COLLECTOR AIRDROP", "AIRDROP") {}
}