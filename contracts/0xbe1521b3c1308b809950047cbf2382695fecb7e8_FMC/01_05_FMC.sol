// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FreeMrktCptlst
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//    FFFFFFFFFFFFFFFFFFFFFFMMMMMMMM               MMMMMMMM        CCCCCCCCCCCCC    //
//    F::::::::::::::::::::FM:::::::M             M:::::::M     CCC::::::::::::C    //
//    F::::::::::::::::::::FM::::::::M           M::::::::M   CC:::::::::::::::C    //
//    FF::::::FFFFFFFFF::::FM:::::::::M         M:::::::::M  C:::::CCCCCCCC::::C    //
//      F:::::F       FFFFFFM::::::::::M       M::::::::::M C:::::C       CCCCCC    //
//      F:::::F             M:::::::::::M     M:::::::::::MC:::::C                  //
//      F::::::FFFFFFFFFF   M:::::::M::::M   M::::M:::::::MC:::::C                  //
//      F:::::::::::::::F   M::::::M M::::M M::::M M::::::MC:::::C                  //
//      F:::::::::::::::F   M::::::M  M::::M::::M  M::::::MC:::::C                  //
//      F::::::FFFFFFFFFF   M::::::M   M:::::::M   M::::::MC:::::C                  //
//      F:::::F             M::::::M    M:::::M    M::::::MC:::::C                  //
//      F:::::F             M::::::M     MMMMM     M::::::M C:::::C       CCCCCC    //
//    FF:::::::FF           M::::::M               M::::::M  C:::::CCCCCCCC::::C    //
//    F::::::::FF           M::::::M               M::::::M   CC:::::::::::::::C    //
//    F::::::::FF           M::::::M               M::::::M     CCC::::::::::::C    //
//    FFFFFFFFFFF           MMMMMMMM               MMMMMMMM        CCCCCCCCCCCCC    //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract FMC is ERC721Creator {
    constructor() ERC721Creator("FreeMrktCptlst", "FMC") {}
}