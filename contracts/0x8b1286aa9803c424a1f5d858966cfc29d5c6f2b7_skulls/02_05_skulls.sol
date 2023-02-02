// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Winterton Collection Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                   _.---._                  //
//                 .'       `.                //
//                 :)       (:                //
//                 \ (@) (@) /                //
//                  \   A   /                 //
//                   )     (                  //
//                   \"""""/                  //
//                    `._.'                   //
//                     .=.                    //
//             .---._.-.=.-._.---.            //
//            / ':-(_.-: :-._)-:` \           //
//           / /' (__.-: :-.__) `\ \          //
//          / /  (___.-` '-.___)  \ \         //
//         / /   (___.-'^`-.___)   \ \        //
//        / /    (___.-'=`-.___)    \ \       //
//       / /     (____.'=`.____)     \ \      //
//      / /       (___.'=`.___)       \ \     //
//    THE   W I N T E R T O N   COLLECTION    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract skulls is ERC1155Creator {
    constructor() ERC1155Creator("The Winterton Collection Editions", "skulls") {}
}