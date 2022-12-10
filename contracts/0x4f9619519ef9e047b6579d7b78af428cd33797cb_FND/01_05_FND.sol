// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Foundation
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//    Description of the collection :                                               //
//                                                                                  //
//    The story of what remains of human civilization, in the year 2321,            //
//    leaving earth in hopes of reaching a new habitable world detected in 2147,    //
//    a potential new home for the foundation of a new civilization.                //
//                                                                                  //
//    Each item in this collection is a piece of the story,                         //
//    uploaded in a non-chronological order.                                        //
//                                                                                  //
//         *             *                          *                               //
//                                      *                     *                     //
//                            *                               ___                   //
//              *                                       |     | |                   //
//                _________##                 *        / \    | |                   //
//               @\\\\\\\\\##    *     |              |--o|===|-|                   //
//      *       @@@\\\\\\\\##\       \|/|/            |---|   | |                   //
//             @@ @@\\\\\\\\\\\    \|\\|//|/     *   /     \  | |                   //
//            @@@@@@@\\\\\\\\\\\    \|\|/|/         |   F   | | |                   //
//           @@@@@@@@@----------|    \\|//          |   N   |=| |                   //
//           @@ @@@ @@__________|     \|/           |   D   | | |                   //
//           @@@@@@@@@__________|     \|/           |_______| |_|                   //
//           @@@@ [email protected]@@__________|      |             |@| |@|  | |                   //
//    __\|/[email protected]@@@[email protected]@@__________|_\|/__|___\|/__\|/___________|_|_                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract FND is ERC1155Creator {
    constructor() ERC1155Creator("Foundation", "FND") {}
}