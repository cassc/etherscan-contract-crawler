// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art Unchained Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//             /\        | |   | |  | |          | |         (_)              | |                                     //
//            /  \   _ __| |_  | |  | |_ __   ___| |__   __ _ _ _ __   ___  __| |                                     //
//           / /\ \ | '__| __| | |  | | '_ \ / __| '_ \ / _` | | '_ \ / _ \/ _` |                                     //
//          / ____ \| |  | |_  | |__| | | | | (__| | | | (_| | | | | |  __/ (_| |                                     //
//         /_/    \_\_|   \__|  \____/|_| |_|\___|_| |_|\__,_|_|_| |_|\___|\__,_|                                     //
//                                                                                                                    //
//         art-unchained.io | Your Metaverse Gateway: Realizing Virtual Visions                                       //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ARTUNCHAINEDS is ERC1155Creator {
    constructor() ERC1155Creator("Art Unchained Editions", "ARTUNCHAINEDS") {}
}