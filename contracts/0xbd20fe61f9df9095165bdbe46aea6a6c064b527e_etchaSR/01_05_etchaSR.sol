// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: etcha Super Rare
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//    EEEEEEEEEEEEEEEEEEEEEE         tttt                             hhhhhhh                                       SSSSSSSSSSSSSSS RRRRRRRRRRRRRRRRR       //
//    E::::::::::::::::::::E      ttt:::t                             h:::::h                                     SS:::::::::::::::SR::::::::::::::::R      //
//    E::::::::::::::::::::E      t:::::t                             h:::::h                                    S:::::SSSSSS::::::SR::::::RRRRRR:::::R     //
//    EE::::::EEEEEEEEE::::E      t:::::t                             h:::::h                                    S:::::S     SSSSSSSRR:::::R     R:::::R    //
//      E:::::E       EEEEEEttttttt:::::ttttttt        cccccccccccccccch::::h hhhhh         aaaaaaaaaaaaa        S:::::S              R::::R     R:::::R    //
//      E:::::E             t:::::::::::::::::t      cc:::::::::::::::ch::::hh:::::hhh      a::::::::::::a       S:::::S              R::::R     R:::::R    //
//      E::::::EEEEEEEEEE   t:::::::::::::::::t     c:::::::::::::::::ch::::::::::::::hh    aaaaaaaaa:::::a       S::::SSSS           R::::RRRRRR:::::R     //
//      E:::::::::::::::E   tttttt:::::::tttttt    c:::::::cccccc:::::ch:::::::hhh::::::h            a::::a        SS::::::SSSSS      R:::::::::::::RR      //
//      E:::::::::::::::E         t:::::t          c::::::c     ccccccch::::::h   h::::::h    aaaaaaa:::::a          SSS::::::::SS    R::::RRRRRR:::::R     //
//      E::::::EEEEEEEEEE         t:::::t          c:::::c             h:::::h     h:::::h  aa::::::::::::a             SSSSSS::::S   R::::R     R:::::R    //
//      E:::::E                   t:::::t          c:::::c             h:::::h     h:::::h a::::aaaa::::::a                  S:::::S  R::::R     R:::::R    //
//      E:::::E       EEEEEE      t:::::t    ttttttc::::::c     ccccccch:::::h     h:::::ha::::a    a:::::a                  S:::::S  R::::R     R:::::R    //
//    EE::::::EEEEEEEE:::::E      t::::::tttt:::::tc:::::::cccccc:::::ch:::::h     h:::::ha::::a    a:::::a      SSSSSSS     S:::::SRR:::::R     R:::::R    //
//    E::::::::::::::::::::E      tt::::::::::::::t c:::::::::::::::::ch:::::h     h:::::ha:::::aaaa::::::a      S::::::SSSSSS:::::SR::::::R     R:::::R    //
//    E::::::::::::::::::::E        tt:::::::::::tt  cc:::::::::::::::ch:::::h     h:::::h a::::::::::aa:::a     S:::::::::::::::SS R::::::R     R:::::R    //
//    EEEEEEEEEEEEEEEEEEEEEE          ttttttttttt      cccccccccccccccchhhhhhh     hhhhhhh  aaaaaaaaaa  aaaa      SSSSSSSSSSSSSSS   RRRRRRRR     RRRRRRR    //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract etchaSR is ERC721Creator {
    constructor() ERC721Creator("etcha Super Rare", "etchaSR") {}
}