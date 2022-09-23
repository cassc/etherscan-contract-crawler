// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wolo Bear
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//    WWWWWWWW                           WWWWWWWW              lllllll                       BBBBBBBBBBBBBBBBB                                                              //
//    W::::::W                           W::::::W              l:::::l                       B::::::::::::::::B                                                             //
//    W::::::W                           W::::::W              l:::::l                       B::::::BBBBBB:::::B                                                            //
//    W::::::W                           W::::::W              l:::::l                       BB:::::B     B:::::B                                                           //
//     W:::::W           WWWWW           W:::::W ooooooooooo    l::::l    ooooooooooo          B::::B     B:::::B    eeeeeeeeeeee    aaaaaaaaaaaaa  rrrrr   rrrrrrrrr       //
//      W:::::W         W:::::W         W:::::Woo:::::::::::oo  l::::l  oo:::::::::::oo        B::::B     B:::::B  ee::::::::::::ee  a::::::::::::a r::::rrr:::::::::r      //
//       W:::::W       W:::::::W       W:::::Wo:::::::::::::::o l::::l o:::::::::::::::o       B::::BBBBBB:::::B  e::::::eeeee:::::eeaaaaaaaaa:::::ar:::::::::::::::::r     //
//        W:::::W     W:::::::::W     W:::::W o:::::ooooo:::::o l::::l o:::::ooooo:::::o       B:::::::::::::BB  e::::::e     e:::::e         a::::arr::::::rrrrr::::::r    //
//         W:::::W   W:::::W:::::W   W:::::W  o::::o     o::::o l::::l o::::o     o::::o       B::::BBBBBB:::::B e:::::::eeeee::::::e  aaaaaaa:::::a r:::::r     r:::::r    //
//          W:::::W W:::::W W:::::W W:::::W   o::::o     o::::o l::::l o::::o     o::::o       B::::B     B:::::Be:::::::::::::::::e aa::::::::::::a r:::::r     rrrrrrr    //
//           W:::::W:::::W   W:::::W:::::W    o::::o     o::::o l::::l o::::o     o::::o       B::::B     B:::::Be::::::eeeeeeeeeee a::::aaaa::::::a r:::::r                //
//            W:::::::::W     W:::::::::W     o::::o     o::::o l::::l o::::o     o::::o       B::::B     B:::::Be:::::::e         a::::a    a:::::a r:::::r                //
//             W:::::::W       W:::::::W      o:::::ooooo:::::ol::::::lo:::::ooooo:::::o     BB:::::BBBBBB::::::Be::::::::e        a::::a    a:::::a r:::::r                //
//              W:::::W         W:::::W       o:::::::::::::::ol::::::lo:::::::::::::::o     B:::::::::::::::::B  e::::::::eeeeeeeea:::::aaaa::::::a r:::::r                //
//               W:::W           W:::W         oo:::::::::::oo l::::::l oo:::::::::::oo      B::::::::::::::::B    ee:::::::::::::e a::::::::::aa:::ar:::::r                //
//                WWW             WWW            ooooooooooo   llllllll   ooooooooooo        BBBBBBBBBBBBBBBBB       eeeeeeeeeeeeee  aaaaaaaaaa  aaaarrrrrrr                //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WLB is ERC721Creator {
    constructor() ERC721Creator("Wolo Bear", "WLB") {}
}