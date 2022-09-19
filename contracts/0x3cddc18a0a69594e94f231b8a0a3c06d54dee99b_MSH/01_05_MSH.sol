// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: M.Sh MAD SIDE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//    MMMMMMMM               MMMMMMMM           SSSSSSSSSSSSSSS HHHHHHHHH     HHHHHHHHH    //
//    M:::::::M             M:::::::M         SS:::::::::::::::SH:::::::H     H:::::::H    //
//    M::::::::M           M::::::::M        S:::::SSSSSS::::::SH:::::::H     H:::::::H    //
//    M:::::::::M         M:::::::::M        S:::::S     SSSSSSSHH::::::H     H::::::HH    //
//    M::::::::::M       M::::::::::M        S:::::S              H:::::H     H:::::H      //
//    M:::::::::::M     M:::::::::::M        S:::::S              H:::::H     H:::::H      //
//    M:::::::M::::M   M::::M:::::::M         S::::SSSS           H::::::HHHHH::::::H      //
//    M::::::M M::::M M::::M M::::::M          SS::::::SSSSS      H:::::::::::::::::H      //
//    M::::::M  M::::M::::M  M::::::M            SSS::::::::SS    H:::::::::::::::::H      //
//    M::::::M   M:::::::M   M::::::M               SSSSSS::::S   H::::::HHHHH::::::H      //
//    M::::::M    M:::::M    M::::::M                    S:::::S  H:::::H     H:::::H      //
//    M::::::M     MMMMM     M::::::M                    S:::::S  H:::::H     H:::::H      //
//    M::::::M               M::::::M        SSSSSSS     S:::::SHH::::::H     H::::::HH    //
//    M::::::M               M::::::M ...... S::::::SSSSSS:::::SH:::::::H     H:::::::H    //
//    M::::::M               M::::::M .::::. S:::::::::::::::SS H:::::::H     H:::::::H    //
//    MMMMMMMM               MMMMMMMM ......  SSSSSSSSSSSSSSS   HHHHHHHHH     HHHHHHHHH    //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract MSH is ERC721Creator {
    constructor() ERC721Creator("M.Sh MAD SIDE", "MSH") {}
}