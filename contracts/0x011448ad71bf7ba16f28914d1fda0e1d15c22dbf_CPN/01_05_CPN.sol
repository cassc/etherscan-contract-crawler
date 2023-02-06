// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chepepen - OPENPEN EDITION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//    PPPPPPPPPPPPPPPPP   EEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPPPPPPPPP   EEEEEEEEEEEEEEEEEEEEEE             CCCCCCCCCCCCCHHHHHHHHH     HHHHHHHHHEEEEEEEEEEEEEEEEEEEEEE       CCCCCCCCCCCCCKKKKKKKKK    KKKKKKK    //
//    P::::::::::::::::P  E::::::::::::::::::::EP::::::::::::::::P  E::::::::::::::::::::E          CCC::::::::::::CH:::::::H     H:::::::HE::::::::::::::::::::E    CCC::::::::::::CK:::::::K    K:::::K    //
//    P::::::PPPPPP:::::P E::::::::::::::::::::EP::::::PPPPPP:::::P E::::::::::::::::::::E        CC:::::::::::::::CH:::::::H     H:::::::HE::::::::::::::::::::E  CC:::::::::::::::CK:::::::K    K:::::K    //
//    PP:::::P     P:::::PEE::::::EEEEEEEEE::::EPP:::::P     P:::::PEE::::::EEEEEEEEE::::E       C:::::CCCCCCCC::::CHH::::::H     H::::::HHEE::::::EEEEEEEEE::::E C:::::CCCCCCCC::::CK:::::::K   K::::::K    //
//      P::::P     P:::::P  E:::::E       EEEEEE  P::::P     P:::::P  E:::::E       EEEEEE      C:::::C       CCCCCC  H:::::H     H:::::H    E:::::E       EEEEEEC:::::C       CCCCCCKK::::::K  K:::::KKK    //
//      P::::P     P:::::P  E:::::E               P::::P     P:::::P  E:::::E                  C:::::C                H:::::H     H:::::H    E:::::E            C:::::C                K:::::K K:::::K       //
//      P::::PPPPPP:::::P   E::::::EEEEEEEEEE     P::::PPPPPP:::::P   E::::::EEEEEEEEEE        C:::::C                H::::::HHHHH::::::H    E::::::EEEEEEEEEE  C:::::C                K::::::K:::::K        //
//      P:::::::::::::PP    E:::::::::::::::E     P:::::::::::::PP    E:::::::::::::::E        C:::::C                H:::::::::::::::::H    E:::::::::::::::E  C:::::C                K:::::::::::K         //
//      P::::PPPPPPPPP      E:::::::::::::::E     P::::PPPPPPPPP      E:::::::::::::::E        C:::::C                H:::::::::::::::::H    E:::::::::::::::E  C:::::C                K:::::::::::K         //
//      P::::P              E::::::EEEEEEEEEE     P::::P              E::::::EEEEEEEEEE        C:::::C                H::::::HHHHH::::::H    E::::::EEEEEEEEEE  C:::::C                K::::::K:::::K        //
//      P::::P              E:::::E               P::::P              E:::::E                  C:::::C                H:::::H     H:::::H    E:::::E            C:::::C                K:::::K K:::::K       //
//      P::::P              E:::::E       EEEEEE  P::::P              E:::::E       EEEEEE      C:::::C       CCCCCC  H:::::H     H:::::H    E:::::E       EEEEEEC:::::C       CCCCCCKK::::::K  K:::::KKK    //
//    PP::::::PP          EE::::::EEEEEEEE:::::EPP::::::PP          EE::::::EEEEEEEE:::::E       C:::::CCCCCCCC::::CHH::::::H     H::::::HHEE::::::EEEEEEEE:::::E C:::::CCCCCCCC::::CK:::::::K   K::::::K    //
//    P::::::::P          E::::::::::::::::::::EP::::::::P          E::::::::::::::::::::E        CC:::::::::::::::CH:::::::H     H:::::::HE::::::::::::::::::::E  CC:::::::::::::::CK:::::::K    K:::::K    //
//    P::::::::P          E::::::::::::::::::::EP::::::::P          E::::::::::::::::::::E          CCC::::::::::::CH:::::::H     H:::::::HE::::::::::::::::::::E    CCC::::::::::::CK:::::::K    K:::::K    //
//    PPPPPPPPPP          EEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPP          EEEEEEEEEEEEEEEEEEEEEE             CCCCCCCCCCCCCHHHHHHHHH     HHHHHHHHHEEEEEEEEEEEEEEEEEEEEEE       CCCCCCCCCCCCCKKKKKKKKK    KKKKKKK    //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CPN is ERC721Creator {
    constructor() ERC721Creator("Chepepen - OPENPEN EDITION", "CPN") {}
}