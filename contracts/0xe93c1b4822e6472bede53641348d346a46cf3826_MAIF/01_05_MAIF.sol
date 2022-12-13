// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MAIF COLLAB
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//    MMMMMMMM               MMMMMMMM               AAA               IIIIIIIIIIFFFFFFFFFFFFFFFFFFFFFF    //
//    M:::::::M             M:::::::M              A:::A              I::::::::IF::::::::::::::::::::F    //
//    M::::::::M           M::::::::M             A:::::A             I::::::::IF::::::::::::::::::::F    //
//    M:::::::::M         M:::::::::M            A:::::::A            II::::::IIFF::::::FFFFFFFFF::::F    //
//    M::::::::::M       M::::::::::M           A:::::::::A             I::::I    F:::::F       FFFFFF    //
//    M:::::::::::M     M:::::::::::M          A:::::A:::::A            I::::I    F:::::F                 //
//    M:::::::M::::M   M::::M:::::::M         A:::::A A:::::A           I::::I    F::::::FFFFFFFFFF       //
//    M::::::M M::::M M::::M M::::::M        A:::::A   A:::::A          I::::I    F:::::::::::::::F       //
//    M::::::M  M::::M::::M  M::::::M       A:::::A     A:::::A         I::::I    F:::::::::::::::F       //
//    M::::::M   M:::::::M   M::::::M      A:::::AAAAAAAAA:::::A        I::::I    F::::::FFFFFFFFFF       //
//    M::::::M    M:::::M    M::::::M     A:::::::::::::::::::::A       I::::I    F:::::F                 //
//    M::::::M     MMMMM     M::::::M    A:::::AAAAAAAAAAAAA:::::A      I::::I    F:::::F                 //
//    M::::::M               M::::::M   A:::::A             A:::::A   II::::::IIFF:::::::FF               //
//    M::::::M               M::::::M  A:::::A               A:::::A  I::::::::IF::::::::FF               //
//    M::::::M               M::::::M A:::::A                 A:::::A I::::::::IF::::::::FF               //
//    MMMMMMMM               MMMMMMMMAAAAAAA                   AAAAAAAIIIIIIIIIIFFFFFFFFFFF               //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MAIF is ERC721Creator {
    constructor() ERC721Creator("MAIF COLLAB", "MAIF") {}
}