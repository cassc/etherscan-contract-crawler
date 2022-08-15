// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: R[DS] by Perrine
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    \______   \ |   _| \______ \  /   _____/ |_   |     //
//     |       _/ |  |    |    |  \ \_____  \    |  |     //
//     |    |   \ |  |    |    `   \/        \   |  |     //
//     |____|_  / |  |_  /_______  /_______  /  _|  |     //
//            \/  |____|         \/        \/  |____|     //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract RDS is ERC721Creator {
    constructor() ERC721Creator("R[DS] by Perrine", "RDS") {}
}