// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RiBT Drops
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//    RRRRRRRRRRRRRRRRR     iiii  BBBBBBBBBBBBBBBBB   TTTTTTTTTTTTTTTTTTTTTTT    //
//    R::::::::::::::::R   i::::i B::::::::::::::::B  T:::::::::::::::::::::T    //
//    R::::::RRRRRR:::::R   iiii  B::::::BBBBBB:::::B T:::::::::::::::::::::T    //
//    RR:::::R     R:::::R        BB:::::B     B:::::BT:::::TT:::::::TT:::::T    //
//      R::::R     R:::::Riiiiiii   B::::B     B:::::BTTTTTT  T:::::T  TTTTTT    //
//      R::::R     R:::::Ri:::::i   B::::B     B:::::B        T:::::T            //
//      R::::RRRRRR:::::R  i::::i   B::::BBBBBB:::::B         T:::::T            //
//      R:::::::::::::RR   i::::i   B:::::::::::::BB          T:::::T            //
//      R::::RRRRRR:::::R  i::::i   B::::BBBBBB:::::B         T:::::T            //
//      R::::R     R:::::R i::::i   B::::B     B:::::B        T:::::T            //
//      R::::R     R:::::R i::::i   B::::B     B:::::B        T:::::T            //
//      R::::R     R:::::R i::::i   B::::B     B:::::B        T:::::T            //
//    RR:::::R     R:::::Ri::::::iBB:::::BBBBBB::::::B      TT:::::::TT          //
//    R::::::R     R:::::Ri::::::iB:::::::::::::::::B       T:::::::::T          //
//    R::::::R     R:::::Ri::::::iB::::::::::::::::B        T:::::::::T          //
//    RRRRRRRR     RRRRRRRiiiiiiiiBBBBBBBBBBBBBBBBB         TTTTTTTTTTT          //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract RiBT is ERC1155Creator {
    constructor() ERC1155Creator("RiBT Drops", "RiBT") {}
}