// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Passion - Genesis Edition
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    *          *        _   *               *         //
//           /\          ((            *                //
//          /  \     *    `                             //
//       * /    \   /\           *                      //
//        /      \ /  \                     *           //
//       /  /\    /    \   *  /\    /\  /\              //
//      /  /  \  /      \    /  \/\/  \/  \             //
//     /  /    \/ /\     \  /    \ \  /    \            //
//    /__/______\/__\/\___\/______\  /______\           //
//    | _ \ /_\  / __|/ __||_ _| / _ \ | \| |           //
//    |  _// _ \ \__ \\__ \ | | | (_) ||    |           //
//    |_| /_/ \_\|___/|___/|___  \___/ |_|\_|           //
//                                                      //
//    https://www.TheWickedHunt.com                     //
//    The Wicked Hunt Photography by Stanley Aryanto    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract TWHPSN is ERC721Creator {
    constructor() ERC721Creator("Passion - Genesis Edition", "TWHPSN") {}
}