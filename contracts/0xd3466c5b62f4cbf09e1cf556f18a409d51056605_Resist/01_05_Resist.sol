// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Resistance
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                  _-o#&&*''''?d:>b\_                  //
//              _o/"`''  '',, dMF9MMMMMHo_              //
//           .o&#'        `"MbHMMMMMMMMMMMHo.           //
//         .o"" '         vodM*$&&HMMMMMMMMMM?.         //
//        ,'              $M&ood,~'`(&##MMMMMMH\        //
//       /               ,MMMMMMM#b?#bobMMMMHMMML       //
//      &              ?MMMMMMMMMMMMMMMMM7MMM$R*Hk      //
//     ?$.            :MMMMMMMMMMMMMMMMMMM/HMMM|`*L     //
//    |               |MMMMMMMMMMMMMMMMMMMMbMH'   T,    //
//    $H#:            `*MMMMMMMMMMMMMMMMMMMMb#}'  `?    //
//    ]MMH#             ""*""""*#MMMMMMMMMMMMM'    -    //
//    MMMMMb_                   |MMMMMMMMMMMP'     :    //
//    HMMMMMMMHo                 `MMMMMMMMMT       .    //
//    ?MMMMMMMMP                  9MMMMMMMM}       -    //
//    -?MMMMMMM                  |MMMMMMMMM?,d-    '    //
//     :|MMMMMM-                 `MMMMMMMT .M|.   :     //
//      .9MMM[                    &MMMMM*' `'    .      //
//       :9MMk                    `MMM#"        -       //
//         &M}                     `          .-        //
//          `&.                             .           //
//            `~,   .                     ./            //
//                . _                  .-               //
//                  '`--._,dd###pp=""'                  //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract Resist is ERC721Creator {
    constructor() ERC721Creator("The Resistance", "Resist") {}
}