// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dreamscapes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                                                                                                                          //
//    KKKKKKKKK    KKKKKKKEEEEEEEEEEEEEEEEEEEEEEZZZZZZZZZZZZZZZZZZZIIIIIIIIII               AAA               IIIIIIIIII    //
//    K:::::::K    K:::::KE::::::::::::::::::::EZ:::::::::::::::::ZI::::::::I              A:::A              I::::::::I    //
//    K:::::::K    K:::::KE::::::::::::::::::::EZ:::::::::::::::::ZI::::::::I             A:::::A             I::::::::I    //
//    K:::::::K   K::::::KEE::::::EEEEEEEEE::::EZ:::ZZZZZZZZ:::::Z II::::::II            A:::::::A            II::::::II    //
//    KK::::::K  K:::::KKK  E:::::E       EEEEEEZZZZZ     Z:::::Z    I::::I             A:::::::::A             I::::I      //
//      K:::::K K:::::K     E:::::E                     Z:::::Z      I::::I            A:::::A:::::A            I::::I      //
//      K::::::K:::::K      E::::::EEEEEEEEEE          Z:::::Z       I::::I           A:::::A A:::::A           I::::I      //
//      K:::::::::::K       E:::::::::::::::E         Z:::::Z        I::::I          A:::::A   A:::::A          I::::I      //
//      K:::::::::::K       E:::::::::::::::E        Z:::::Z         I::::I         A:::::A     A:::::A         I::::I      //
//      K::::::K:::::K      E::::::EEEEEEEEEE       Z:::::Z          I::::I        A:::::AAAAAAAAA:::::A        I::::I      //
//      K:::::K K:::::K     E:::::E                Z:::::Z           I::::I       A:::::::::::::::::::::A       I::::I      //
//    KK::::::K  K:::::KKK  E:::::E       EEEEEEZZZ:::::Z     ZZZZZ  I::::I      A:::::AAAAAAAAAAAAA:::::A      I::::I      //
//    K:::::::K   K::::::KEE::::::EEEEEEEE:::::EZ::::::ZZZZZZZZ:::ZII::::::II   A:::::A             A:::::A   II::::::II    //
//    K:::::::K    K:::::KE::::::::::::::::::::EZ:::::::::::::::::ZI::::::::I  A:::::A               A:::::A  I::::::::I    //
//    K:::::::K    K:::::KE::::::::::::::::::::EZ:::::::::::::::::ZI::::::::I A:::::A                 A:::::A I::::::::I    //
//    KKKKKKKKK    KKKKKKKEEEEEEEEEEEEEEEEEEEEEEZZZZZZZZZZZZZZZZZZZIIIIIIIIIIAAAAAAA                   AAAAAAAIIIIIIIIII    //
//                                                                                                                          //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DREAM is ERC721Creator {
    constructor() ERC721Creator("Dreamscapes", "DREAM") {}
}