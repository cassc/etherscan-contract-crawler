// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vénus
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//    VVVVVVVV           VVVVVVVVEEEEEEEEEEEEEEEEEEEEEENNNNNNNN        NNNNNNNNUUUUUUUU     UUUUUUUU   SSSSSSSSSSSSSSS     //
//    V::::::V           V::::::VE::::::::::::::::::::EN:::::::N       N::::::NU::::::U     U::::::U SS:::::::::::::::S    //
//    V::::::V           V::::::VE::::::::::::::::::::EN::::::::N      N::::::NU::::::U     U::::::US:::::SSSSSS::::::S    //
//    V::::::V           V::::::VEE::::::EEEEEEEEE::::EN:::::::::N     N::::::NUU:::::U     U:::::UUS:::::S     SSSSSSS    //
//     V:::::V           V:::::V   E:::::E       EEEEEEN::::::::::N    N::::::N U:::::U     U:::::U S:::::S                //
//      V:::::V         V:::::V    E:::::E             N:::::::::::N   N::::::N U:::::D     D:::::U S:::::S                //
//       V:::::V       V:::::V     E::::::EEEEEEEEEE   N:::::::N::::N  N::::::N U:::::D     D:::::U  S::::SSSS             //
//        V:::::V     V:::::V      E:::::::::::::::E   N::::::N N::::N N::::::N U:::::D     D:::::U   SS::::::SSSSS        //
//         V:::::V   V:::::V       E:::::::::::::::E   N::::::N  N::::N:::::::N U:::::D     D:::::U     SSS::::::::SS      //
//          V:::::V V:::::V        E::::::EEEEEEEEEE   N::::::N   N:::::::::::N U:::::D     D:::::U        SSSSSS::::S     //
//           V:::::V:::::V         E:::::E             N::::::N    N::::::::::N U:::::D     D:::::U             S:::::S    //
//            V:::::::::V          E:::::E       EEEEEEN::::::N     N:::::::::N U::::::U   U::::::U             S:::::S    //
//             V:::::::V         EE::::::EEEEEEEE:::::EN::::::N      N::::::::N U:::::::UUU:::::::U SSSSSSS     S:::::S    //
//              V:::::V          E::::::::::::::::::::EN::::::N       N:::::::N  UU:::::::::::::UU  S::::::SSSSSS:::::S    //
//               V:::V           E::::::::::::::::::::EN::::::N        N::::::N    UU:::::::::UU    S:::::::::::::::SS     //
//                VVV            EEEEEEEEEEEEEEEEEEEEEENNNNNNNN         NNNNNNN      UUUUUUUUU       SSSSSSSSSSSSSSS       //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VENUS is ERC721Creator {
    constructor() ERC721Creator(unicode"Vénus", "VENUS") {}
}