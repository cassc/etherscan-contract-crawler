// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEEPEST
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//    DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPPPPPPPPP   EEEEEEEEEEEEEEEEEEEEEE   SSSSSSSSSSSSSSS TTTTTTTTTTTTTTTTTTTTTTT    //
//    D::::::::::::DDD   E::::::::::::::::::::EE::::::::::::::::::::EP::::::::::::::::P  E::::::::::::::::::::E SS:::::::::::::::ST:::::::::::::::::::::T    //
//    D:::::::::::::::DD E::::::::::::::::::::EE::::::::::::::::::::EP::::::PPPPPP:::::P E::::::::::::::::::::ES:::::SSSSSS::::::ST:::::::::::::::::::::T    //
//    DDD:::::DDDDD:::::DEE::::::EEEEEEEEE::::EEE::::::EEEEEEEEE::::EPP:::::P     P:::::PEE::::::EEEEEEEEE::::ES:::::S     SSSSSSST:::::TT:::::::TT:::::T    //
//      D:::::D    D:::::D E:::::E       EEEEEE  E:::::E       EEEEEE  P::::P     P:::::P  E:::::E       EEEEEES:::::S            TTTTTT  T:::::T  TTTTTT    //
//      D:::::D     D:::::DE:::::E               E:::::E               P::::P     P:::::P  E:::::E             S:::::S                    T:::::T            //
//      D:::::D     D:::::DE::::::EEEEEEEEEE     E::::::EEEEEEEEEE     P::::PPPPPP:::::P   E::::::EEEEEEEEEE    S::::SSSS                 T:::::T            //
//      D:::::D     D:::::DE:::::::::::::::E     E:::::::::::::::E     P:::::::::::::PP    E:::::::::::::::E     SS::::::SSSSS            T:::::T            //
//      D:::::D     D:::::DE:::::::::::::::E     E:::::::::::::::E     P::::PPPPPPPPP      E:::::::::::::::E       SSS::::::::SS          T:::::T            //
//      D:::::D     D:::::DE::::::EEEEEEEEEE     E::::::EEEEEEEEEE     P::::P              E::::::EEEEEEEEEE          SSSSSS::::S         T:::::T            //
//      D:::::D     D:::::DE:::::E               E:::::E               P::::P              E:::::E                         S:::::S        T:::::T            //
//      D:::::D    D:::::D E:::::E       EEEEEE  E:::::E       EEEEEE  P::::P              E:::::E       EEEEEE            S:::::S        T:::::T            //
//    DDD:::::DDDDD:::::DEE::::::EEEEEEEE:::::EEE::::::EEEEEEEE:::::EPP::::::PP          EE::::::EEEEEEEE:::::ESSSSSSS     S:::::S      TT:::::::TT          //
//    D:::::::::::::::DD E::::::::::::::::::::EE::::::::::::::::::::EP::::::::P          E::::::::::::::::::::ES::::::SSSSSS:::::S      T:::::::::T          //
//    D::::::::::::DDD   E::::::::::::::::::::EE::::::::::::::::::::EP::::::::P          E::::::::::::::::::::ES:::::::::::::::SS       T:::::::::T          //
//    DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPP          EEEEEEEEEEEEEEEEEEEEEE SSSSSSSSSSSSSSS         TTTTTTTTTTT          //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DPST is ERC721Creator {
    constructor() ERC721Creator("DEEPEST", "DPST") {}
}