// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glam Beckett Winter
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    *   *  *   ()   *   *               //
//     *   *     /\  *   *  *             //
//       *   *  /i\\    *  *              //
//        *     o/\\  *      *            //
//     *       ///\i\    *                //
//         *   /*/o\\  *    *             //
//       *    /i//\*\  *   *              //
//         *  /o/*\\i\   *                //
//      *    //i//o\\\\     *             //
//        * /*////\\\\i\*                 //
//     *    //o//i\\*\\\   *              //
//       * /i///*/\\\\\o\   *             //
//      *    *   ||     * Glam Beckett    //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract GBW is ERC721Creator {
    constructor() ERC721Creator("Glam Beckett Winter", "GBW") {}
}