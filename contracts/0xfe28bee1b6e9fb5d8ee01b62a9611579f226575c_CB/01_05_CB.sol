// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: carpe diem 00002
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//    ............................................................    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    MMMMMNXXXXNNWMMMMMMNXXXXXXNWMMMMMNXXXXXNWMMWNXXXXXXXXNMMMMMM    //
//    MMMMWkllllllokXMMMNkllllllxNMMMMNxlllllxNMMXdlccllcllxNMMMMM    //
//    MMMMNx::::::::dXMMNx::::::dNMMMMXo:::::oXMMXo::::::::dNMMMMM    //
//    MMMMNx:::loc::c0MMNx::::clxNMMMMKl:::::l0MMXdlc::::clxNMMMMM    //
//    MMMMNx:::dKx::cOWMNx:::oKNNMMMMM0c:::::cOMMWNXkc::lOXNWMMMMM    //
//    MMMMNx:::dKx::ckWMNx:::dNMMMMMMWOc::lc::kWMMMMOc::lKMMMMMMMM    //
//    MMMMNx:::oOo::cOMMNx:::o0XNMMMMWk::col::xNMMMWOc::lKMMMMMMMM    //
//    XXXXKd::::c::cd0XXKd::::clxKXXXKd::cdl::oKNXXXkc::lOXXXXXXXX    //
//    KKKK0o:::::::cdOKKOo::::::d0KKKOl::ldl::lkKKK0xc::ckKKKKKKKK    //
//    KKKK0o:::coc:::d0K0o:::cllx0KKKkl::lxo::cxKKK0xc::ckKKKKKKKK    //
//    KKKK0o:::oko:::oOKOo:::oO00KKKKkc::ldl::cx0KK0xc::ckKKKKKKKK    //
//    KKKK0o:::oko:::oOKOo:::oOKKKK00xc::::::::d0KK0xc::ckKKKKKKKK    //
//    KKKK0o:::oko:::oOKOo:::oO000K0Od:::::::::o0KK0xc::ckKKKKKKKK    //
//    KKKK0o:::coc:::oOKOo:::clloOK0Oo:::col:::lOKK0xc::ckKKKKKKKK    //
//    KKKK0o:::::::::d0KOo::::::ckKOko:::oOx:::lkKK0xc::ckKKKKKKKK    //
//    KKKK0d:::::::cok0K0o::::::lkKOxl:::dOxc::ck0K0xc::lkKKKKKKKK    //
//    KKKK0OkkkkkkkO0KKK0Okkkkkkk0K0OkkkkO0OkkkkOKKKOkkkk0KKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract CB is ERC1155Creator {
    constructor() ERC1155Creator("carpe diem 00002", "CB") {}
}