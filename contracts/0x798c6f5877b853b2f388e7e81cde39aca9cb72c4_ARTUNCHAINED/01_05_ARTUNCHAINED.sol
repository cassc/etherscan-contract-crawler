// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art Unchained
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                    _     _    _            _           _                _                                  //
//         /\        | |   | |  | |          | |         (_)              | |                                 //
//        /  \   _ __| |_  | |  | |_ __   ___| |__   __ _ _ _ __   ___  __| |                                 //
//       / /\ \ | '__| __| | |  | | '_ \ / __| '_ \ / _` | | '_ \ / _ \/ _` |                                 //
//      / ____ \| |  | |_  | |__| | | | | (__| | | | (_| | | | | |  __/ (_| |                                 //
//     /_/    \_\_|   \__|  \____/|_| |_|\___|_| |_|\__,_|_|_| |_|\___|\__,_|                                 //
//                                                                                                            //
//     art-unchained.io | creating and curating customized virtual galleries                                  //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ARTUNCHAINED is ERC721Creator {
    constructor() ERC721Creator("Art Unchained", "ARTUNCHAINED") {}
}