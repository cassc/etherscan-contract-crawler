// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pondverse
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                   dddddddd                                                                                                      //
//    PPPPPPPPPPPPPPPPP                                              d::::::d                                                                                                      //
//    P::::::::::::::::P                                             d::::::d                                                                                                      //
//    P::::::PPPPPP:::::P                                            d::::::d                                                                                                      //
//    PP:::::P     P:::::P                                           d:::::d                                                                                                       //
//      P::::P     P:::::P ooooooooooo  nnnn  nnnnnnnn       ddddddddd:::::vvvvvvv           vvvvvvveeeeeeeeeeee   rrrrr   rrrrrrrrr      ssssssssss      eeeeeeeeeeee             //
//      P::::P     P:::::oo:::::::::::oon:::nn::::::::nn   dd::::::::::::::dv:::::v         v:::::ee::::::::::::ee r::::rrr:::::::::r   ss::::::::::s   ee::::::::::::ee           //
//      P::::PPPPPP:::::o:::::::::::::::n::::::::::::::nn d::::::::::::::::d v:::::v       v:::::e::::::eeeee:::::er:::::::::::::::::rss:::::::::::::s e::::::eeeee:::::ee         //
//      P:::::::::::::PPo:::::ooooo:::::nn:::::::::::::::d:::::::ddddd:::::d  v:::::v     v:::::e::::::e     e:::::rr::::::rrrrr::::::s::::::ssss:::::e::::::e     e:::::e         //
//      P::::PPPPPPPPP  o::::o     o::::o n:::::nnnn:::::d::::::d    d:::::d   v:::::v   v:::::ve:::::::eeeee::::::er:::::r     r:::::rs:::::s  sssssse:::::::eeeee::::::e         //
//      P::::P          o::::o     o::::o n::::n    n::::d:::::d     d:::::d    v:::::v v:::::v e:::::::::::::::::e r:::::r     rrrrrrr  s::::::s     e:::::::::::::::::e          //
//      P::::P          o::::o     o::::o n::::n    n::::d:::::d     d:::::d     v:::::v:::::v  e::::::eeeeeeeeeee  r:::::r                 s::::::s  e::::::eeeeeeeeeee           //
//      P::::P          o::::o     o::::o n::::n    n::::d:::::d     d:::::d      v:::::::::v   e:::::::e           r:::::r           ssssss   s:::::se:::::::e                    //
//    PP::::::PP        o:::::ooooo:::::o n::::n    n::::d::::::ddddd::::::dd      v:::::::v    e::::::::e          r:::::r           s:::::ssss::::::e::::::::e                   //
//    P::::::::P        o:::::::::::::::o n::::n    n::::nd:::::::::::::::::d       v:::::v      e::::::::eeeeeeee  r:::::r           s::::::::::::::s e::::::::eeeeeeee           //
//    P::::::::P         oo:::::::::::oo  n::::n    n::::n d:::::::::ddd::::d        v:::v        ee:::::::::::::e  r:::::r            s:::::::::::ss   ee:::::::::::::e           //
//    PPPPPPPPPP           ooooooooooo    nnnnnn    nnnnnn  ddddddddd   ddddd         vvv           eeeeeeeeeeeeee  rrrrrrr             sssssssssss       eeeeeeeeeeeeee           //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PND is ERC1155Creator {
    constructor() ERC1155Creator("Pondverse", "PND") {}
}