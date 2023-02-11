// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AMC to the MOON
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                   AAA               MMMMMMMM               MMMMMMMM        CCCCCCCCCCCCC    //
//                  A:::A              M:::::::M             M:::::::M     CCC::::::::::::C    //
//                 A:::::A             M::::::::M           M::::::::M   CC:::::::::::::::C    //
//                A:::::::A            M:::::::::M         M:::::::::M  C:::::CCCCCCCC::::C    //
//               A:::::::::A           M::::::::::M       M::::::::::M C:::::C       CCCCCC    //
//              A:::::A:::::A          M:::::::::::M     M:::::::::::MC:::::C                  //
//             A:::::A A:::::A         M:::::::M::::M   M::::M:::::::MC:::::C                  //
//            A:::::A   A:::::A        M::::::M M::::M M::::M M::::::MC:::::C                  //
//           A:::::A     A:::::A       M::::::M  M::::M::::M  M::::::MC:::::C                  //
//          A:::::AAAAAAAAA:::::A      M::::::M   M:::::::M   M::::::MC:::::C                  //
//         A:::::::::::::::::::::A     M::::::M    M:::::M    M::::::MC:::::C                  //
//        A:::::AAAAAAAAAAAAA:::::A    M::::::M     MMMMM     M::::::M C:::::C       CCCCCC    //
//       A:::::A             A:::::A   M::::::M               M::::::M  C:::::CCCCCCCC::::C    //
//      A:::::A               A:::::A  M::::::M               M::::::M   CC:::::::::::::::C    //
//     A:::::A                 A:::::A M::::::M               M::::::M     CCC::::::::::::C    //
//    AAAAAAA                   AAAAAAAMMMMMMMM               MMMMMMMM        CCCCCCCCCCCCC    //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract AMC is ERC1155Creator {
    constructor() ERC1155Creator("AMC to the MOON", "AMC") {}
}