// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: For The Culture
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    %%%                 //
//       =====            //
//      &%&%%%&           //
//      %& < <%           //
//       &\__/            //
//        \ |____         //
//       .', ,  ()        //
//      / -.  _)|         //
//     |_(_.    |         //
//     '-'\  )  |         //
//     mrf )    |         //
//        /  .  ).        //
//       /    _. |        //
//     /'---':.-'|        //
//    (__.' /    /        //
//     \   ( /  /         //
//      \ /  _  |         //
//       \  |  '|         //
//       | . \  |         //
//       |(     |         //
//       |  \ \ |         //
//        \  )\ |         //
//       __)/ / \         //
//    --"--(_.Ooo'----    //
//                        //
//                        //
////////////////////////////


contract FTC is ERC721Creator {
    constructor() ERC721Creator("For The Culture", "FTC") {}
}