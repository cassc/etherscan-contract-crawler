// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AEPHAII
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//         _    _____ ____  _   _    _    ___     //
//        / \  | ____|  _ \| | | |  / \  |_ _|    //
//       / _ \ |  _| | |_) | |_| | / _ \  | |     //
//      / ___ \| |___|  __/|  _  |/ ___ \ | |     //
//     /_/   \_\_____|_|   |_| |_/_/   \_\___|    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract AEPHAI is ERC721Creator {
    constructor() ERC721Creator("AEPHAII", "AEPHAI") {}
}