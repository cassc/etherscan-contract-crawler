// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KEEEP-E
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//    KKKKKKKKK    KKKKKKKEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPPPPPPPPP                    EEEEEEEEEEEEEEEEEEEEEE    //
//    K:::::::K    K:::::KE::::::::::::::::::::EE::::::::::::::::::::EE::::::::::::::::::::EP::::::::::::::::P                   E::::::::::::::::::::E    //
//    K:::::::K    K:::::KE::::::::::::::::::::EE::::::::::::::::::::EE::::::::::::::::::::EP::::::PPPPPP:::::P                  E::::::::::::::::::::E    //
//    K:::::::K   K::::::KEE::::::EEEEEEEEE::::EEE::::::EEEEEEEEE::::EEE::::::EEEEEEEEE::::EPP:::::P     P:::::P                 EE::::::EEEEEEEEE::::E    //
//    KK::::::K  K:::::KKK  E:::::E       EEEEEE  E:::::E       EEEEEE  E:::::E       EEEEEE  P::::P     P:::::P                   E:::::E       EEEEEE    //
//      K:::::K K:::::K     E:::::E               E:::::E               E:::::E               P::::P     P:::::P                   E:::::E                 //
//      K::::::K:::::K      E::::::EEEEEEEEEE     E::::::EEEEEEEEEE     E::::::EEEEEEEEEE     P::::PPPPPP:::::P                    E::::::EEEEEEEEEE       //
//      K:::::::::::K       E:::::::::::::::E     E:::::::::::::::E     E:::::::::::::::E     P:::::::::::::PP   ---------------   E:::::::::::::::E       //
//      K:::::::::::K       E:::::::::::::::E     E:::::::::::::::E     E:::::::::::::::E     P::::PPPPPPPPP     -:::::::::::::-   E:::::::::::::::E       //
//      K::::::K:::::K      E::::::EEEEEEEEEE     E::::::EEEEEEEEEE     E::::::EEEEEEEEEE     P::::P             ---------------   E::::::EEEEEEEEEE       //
//      K:::::K K:::::K     E:::::E               E:::::E               E:::::E               P::::P                               E:::::E                 //
//    KK::::::K  K:::::KKK  E:::::E       EEEEEE  E:::::E       EEEEEE  E:::::E       EEEEEE  P::::P                               E:::::E       EEEEEE    //
//    K:::::::K   K::::::KEE::::::EEEEEEEE:::::EEE::::::EEEEEEEE:::::EEE::::::EEEEEEEE:::::EPP::::::PP                           EE::::::EEEEEEEE:::::E    //
//    K:::::::K    K:::::KE::::::::::::::::::::EE::::::::::::::::::::EE::::::::::::::::::::EP::::::::P                           E::::::::::::::::::::E    //
//    K:::::::K    K:::::KE::::::::::::::::::::EE::::::::::::::::::::EE::::::::::::::::::::EP::::::::P                           E::::::::::::::::::::E    //
//    KKKKKKKKK    KKKKKKKEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPP                           EEEEEEEEEEEEEEEEEEEEEE    //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KEEEPE is ERC721Creator {
    constructor() ERC721Creator("KEEEP-E", "KEEEPE") {}
}