// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mercedes-Benz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//    RRRRRRRRRRRRRRRRR                                            iiii lllllll          //
//    R::::::::::::::::R                                          i::::il:::::l          //
//    R::::::RRRRRR:::::R                                          iiii l:::::l          //
//    RR:::::R     R:::::R                                              l:::::l          //
//      R::::R     R:::::R aaaaaaaaaaaaa     mmmmmmm    mmmmmmm  iiiiiii l::::l          //
//      R::::R     R:::::R a::::::::::::a  mm:::::::m  m:::::::mmi:::::i l::::l          //
//      R::::RRRRRR:::::R  aaaaaaaaa:::::am::::::::::mm::::::::::mi::::i l::::l          //
//      R:::::::::::::RR            a::::am::::::::::::::::::::::mi::::i l::::l          //
//      R::::RRRRRR:::::R    aaaaaaa:::::am:::::mmm::::::mmm:::::mi::::i l::::l          //
//      R::::R     R:::::R aa::::::::::::am::::m   m::::m   m::::mi::::i l::::l          //
//      R::::R     R:::::Ra::::aaaa::::::am::::m   m::::m   m::::mi::::i l::::l          //
//      R::::R     R:::::a::::a    a:::::am::::m   m::::m   m::::mi::::i l::::l          //
//    RR:::::R     R:::::a::::a    a:::::am::::m   m::::m   m::::i::::::l::::::l         //
//    R::::::R     R:::::a:::::aaaa::::::am::::m   m::::m   m::::i::::::l::::::l         //
//    R::::::R     R:::::Ra::::::::::aa:::m::::m   m::::m   m::::i::::::l::::::l         //
//    RRRRRRRR     RRRRRRR aaaaaaaaaa  aaammmmmm   mmmmmm   mmmmmiiiiiiillllllll         //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract SPL is ERC721Creator {
    constructor() ERC721Creator("Mercedes-Benz", "SPL") {}
}