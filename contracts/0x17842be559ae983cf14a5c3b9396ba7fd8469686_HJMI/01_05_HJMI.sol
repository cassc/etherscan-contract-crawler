// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HEJEEMI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//    HHHHHHHHH     HHHHHHHHHEEEEEEEEEEEEEEEEEEEEEE          JJJJJJJJJJJEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEMMMMMMMM               MMMMMMMMIIIIIIIIII    //
//    H:::::::H     H:::::::HE::::::::::::::::::::E          J:::::::::JE::::::::::::::::::::EE::::::::::::::::::::EM:::::::M             M:::::::MI::::::::I    //
//    H:::::::H     H:::::::HE::::::::::::::::::::E          J:::::::::JE::::::::::::::::::::EE::::::::::::::::::::EM::::::::M           M::::::::MI::::::::I    //
//    HH::::::H     H::::::HHEE::::::EEEEEEEEE::::E          JJ:::::::JJEE::::::EEEEEEEEE::::EEE::::::EEEEEEEEE::::EM:::::::::M         M:::::::::MII::::::II    //
//      H:::::H     H:::::H    E:::::E       EEEEEE            J:::::J    E:::::E       EEEEEE  E:::::E       EEEEEEM::::::::::M       M::::::::::M  I::::I      //
//      H:::::H     H:::::H    E:::::E                         J:::::J    E:::::E               E:::::E             M:::::::::::M     M:::::::::::M  I::::I      //
//      H::::::HHHHH::::::H    E::::::EEEEEEEEEE               J:::::J    E::::::EEEEEEEEEE     E::::::EEEEEEEEEE   M:::::::M::::M   M::::M:::::::M  I::::I      //
//      H:::::::::::::::::H    E:::::::::::::::E               J:::::j    E:::::::::::::::E     E:::::::::::::::E   M::::::M M::::M M::::M M::::::M  I::::I      //
//      H:::::::::::::::::H    E:::::::::::::::E               J:::::J    E:::::::::::::::E     E:::::::::::::::E   M::::::M  M::::M::::M  M::::::M  I::::I      //
//      H::::::HHHHH::::::H    E::::::EEEEEEEEEE   JJJJJJJ     J:::::J    E::::::EEEEEEEEEE     E::::::EEEEEEEEEE   M::::::M   M:::::::M   M::::::M  I::::I      //
//      H:::::H     H:::::H    E:::::E             J:::::J     J:::::J    E:::::E               E:::::E             M::::::M    M:::::M    M::::::M  I::::I      //
//      H:::::H     H:::::H    E:::::E       EEEEEEJ::::::J   J::::::J    E:::::E       EEEEEE  E:::::E       EEEEEEM::::::M     MMMMM     M::::::M  I::::I      //
//    HH::::::H     H::::::HHEE::::::EEEEEEEE:::::EJ:::::::JJJ:::::::J  EE::::::EEEEEEEE:::::EEE::::::EEEEEEEE:::::EM::::::M               M::::::MII::::::II    //
//    H:::::::H     H:::::::HE::::::::::::::::::::E JJ:::::::::::::JJ   E::::::::::::::::::::EE::::::::::::::::::::EM::::::M               M::::::MI::::::::I    //
//    H:::::::H     H:::::::HE::::::::::::::::::::E   JJ:::::::::JJ     E::::::::::::::::::::EE::::::::::::::::::::EM::::::M               M::::::MI::::::::I    //
//    HHHHHHHHH     HHHHHHHHHEEEEEEEEEEEEEEEEEEEEEE     JJJJJJJJJ       EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEMMMMMMMM               MMMMMMMMIIIIIIIIII    //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HJMI is ERC1155Creator {
    constructor() ERC1155Creator("HEJEEMI", "HJMI") {}
}