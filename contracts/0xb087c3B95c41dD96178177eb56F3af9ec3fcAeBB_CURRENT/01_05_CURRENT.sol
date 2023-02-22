// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CURRENT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                               //
//                                                                                                                                                               //
//            CCCCCCCCCCCCCUUUUUUUU     UUUUUUUURRRRRRRRRRRRRRRRR   RRRRRRRRRRRRRRRRR   EEEEEEEEEEEEEEEEEEEEEENNNNNNNN        NNNNNNNNTTTTTTTTTTTTTTTTTTTTTTT    //
//         CCC::::::::::::CU::::::U     U::::::UR::::::::::::::::R  R::::::::::::::::R  E::::::::::::::::::::EN:::::::N       N::::::NT:::::::::::::::::::::T    //
//       CC:::::::::::::::CU::::::U     U::::::UR::::::RRRRRR:::::R R::::::RRRRRR:::::R E::::::::::::::::::::EN::::::::N      N::::::NT:::::::::::::::::::::T    //
//      C:::::CCCCCCCC::::CUU:::::U     U:::::UURR:::::R     R:::::RRR:::::R     R:::::REE::::::EEEEEEEEE::::EN:::::::::N     N::::::NT:::::TT:::::::TT:::::T    //
//     C:::::C       CCCCCC U:::::U     U:::::U   R::::R     R:::::R  R::::R     R:::::R  E:::::E       EEEEEEN::::::::::N    N::::::NTTTTTT  T:::::T  TTTTTT    //
//    C:::::C               U:::::D     D:::::U   R::::R     R:::::R  R::::R     R:::::R  E:::::E             N:::::::::::N   N::::::N        T:::::T            //
//    C:::::C               U:::::D     D:::::U   R::::RRRRRR:::::R   R::::RRRRRR:::::R   E::::::EEEEEEEEEE   N:::::::N::::N  N::::::N        T:::::T            //
//    C:::::C               U:::::D     D:::::U   R:::::::::::::RR    R:::::::::::::RR    E:::::::::::::::E   N::::::N N::::N N::::::N        T:::::T            //
//    C:::::C               U:::::D     D:::::U   R::::RRRRRR:::::R   R::::RRRRRR:::::R   E:::::::::::::::E   N::::::N  N::::N:::::::N        T:::::T            //
//    C:::::C               U:::::D     D:::::U   R::::R     R:::::R  R::::R     R:::::R  E::::::EEEEEEEEEE   N::::::N   N:::::::::::N        T:::::T            //
//    C:::::C               U:::::D     D:::::U   R::::R     R:::::R  R::::R     R:::::R  E:::::E             N::::::N    N::::::::::N        T:::::T            //
//     C:::::C       CCCCCC U::::::U   U::::::U   R::::R     R:::::R  R::::R     R:::::R  E:::::E       EEEEEEN::::::N     N:::::::::N        T:::::T            //
//      C:::::CCCCCCCC::::C U:::::::UUU:::::::U RR:::::R     R:::::RRR:::::R     R:::::REE::::::EEEEEEEE:::::EN::::::N      N::::::::N      TT:::::::TT          //
//       CC:::::::::::::::C  UU:::::::::::::UU  R::::::R     R:::::RR::::::R     R:::::RE::::::::::::::::::::EN::::::N       N:::::::N      T:::::::::T          //
//         CCC::::::::::::C    UU:::::::::UU    R::::::R     R:::::RR::::::R     R:::::RE::::::::::::::::::::EN::::::N        N::::::N      T:::::::::T          //
//            CCCCCCCCCCCCC      UUUUUUUUU      RRRRRRRR     RRRRRRRRRRRRRRR     RRRRRRREEEEEEEEEEEEEEEEEEEEEENNNNNNNN         NNNNNNN      TTTTTTTTTTT          //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CURRENT is ERC1155Creator {
    constructor() ERC1155Creator("CURRENT", "CURRENT") {}
}