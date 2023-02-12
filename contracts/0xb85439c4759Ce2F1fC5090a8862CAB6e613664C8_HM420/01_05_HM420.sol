// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Haze Mist
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//       ▄█    █▄       ▄████████  ▄███████▄     ▄████████        ▄▄▄▄███▄▄▄▄    ▄█     ▄████████     ███         //
//      ███    ███     ███    ███ ██▀     ▄██   ███    ███      ▄██▀▀▀███▀▀▀██▄ ███    ███    ███ ▀█████████▄     //
//      ███    ███     ███    ███       ▄███▀   ███    █▀       ███   ███   ███ ███▌   ███    █▀     ▀███▀▀██     //
//     ▄███▄▄▄▄███▄▄   ███    ███  ▀█▀▄███▀▄▄  ▄███▄▄▄          ███   ███   ███ ███▌   ███            ███   ▀     //
//    ▀▀███▀▀▀▀███▀  ▀███████████   ▄███▀   ▀ ▀▀███▀▀▀          ███   ███   ███ ███▌ ▀███████████     ███         //
//      ███    ███     ███    ███ ▄███▀         ███    █▄       ███   ███   ███ ███           ███     ███         //
//      ███    ███     ███    ███ ███▄     ▄█   ███    ███      ███   ███   ███ ███     ▄█    ███     ███         //
//      ███    █▀      ███    █▀   ▀████████▀   ██████████       ▀█   ███   █▀  █▀    ▄████████▀     ▄████▀       //
//                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWOxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWkl0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXx:kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOo;dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0oc;cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdcc::l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk::::::xNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkl::::::cdXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl:::::::;lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd::::::::lxKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKdc::::::::::kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXo::::::::::l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMW        //
//    MMMMMMMMMMNO0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkl::::::::::cxXMMMMMMMMMMMMMMMMMMMMMMMMMWNO0WMMMMMMMMMW        //
//    MMMMMMMMMMMXxd0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd::::::::::::xNMMMMMMMMMMMMMMMMMMMMMMMMNOdkNMMMMMMMMMMW        //
//    MMMMMMMMMMMMNkld0NMMMMMMMMMMMMMMMMMMMMMMMMMWOl:::::::::::ckWMMMMMMMMMMMMMMMMMMMMMMNOolONMMMMMMMMMMMW        //
//    MMMMMMMMMMMMWNOc:oO0NWMMMMMMMMMMMMMMMMMMMMMWk:::::::::::::xWMMMMMMMMMMMMMMMMMMWN0ko:l0WMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMNd:::coxkXWMMMMMMMMMMMMMMMMMW0o::::::::::::oKWMMMMMMMMMMMMMMMWXkxo::::xWMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMWKo::::::d0XNMMMMMMMMMMMMMMMW0l::::::::::::lOWMMMMMMMMMMMMMNX0o::::::dKWMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMWkc::::::ccxXWWMMMMMMMMMMMMMKo::::::::::::lKMMMMMMMMMMMWWXdcc::::::cOWMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMNOl::::::::ldONWMMMMMMMMMMMKo::::::::::::xNMMMMMMMMMWNkdl::::::::oONMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMXd::::::::::cokXWMMMMMMMMMXd::::::::::::kNMMMMMMMWKxoc::::::::::xNMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMWXkl:::::::::::ox0WMMMMMMMXd:::::::::::oKWMMMMMW0xo:::::::::::oONWMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMNOl::::::::::::lONWMMMMMNx:::::::::::l0WMMMWXkl::::::::::::l0WMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMWXkc::::::::::::xXWMMMMWOc:::::::::ckNMMMWKd::::::::::::lkXWMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMW0xl::::::::::clOWMMMWOc:::::::::l0WMWNkl::::::::::coxKWMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMWKo:::::::::::cxXWMMXd:::::::::oKWWKdc:::::::::::dKWMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWN0d:::::::::::dKWMWOc:::::::l0WW0o::::::::::cx0NWMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xl:::::::::oKMW0l:::::::oKW0l:::::::::lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMWXKKXNNWWWWNXNWWWWMWMMMMMMMMW0dc::::::::oKWNk::::::l0N0o::::::::ldKWMMMMMMMMMMWWWWNNWWWWWNNXKKXWMW        //
//    MMMNK0kxdoddoollddoxxxkkk0O0XNWMWXkl:::::::lKW0l:::::dX0l:::::::lkXWWWNX0O0kkkxkxoddllooddddxk0XNWMW        //
//    MMMMMMMWKkoc:::::::::::::::cloxkOKKK0dc:::::oKXd::::oK0l:::::cd0KKKOkdol::::::::::::::::coOKNWMMMMMW        //
//    MMMMMMMMMWN0xlc::::::::::::::::::cldxkOko::::o0Oc::cO0l:::cdkOkxdlc::::::::::::::::::cokKNWMMMMMMMMW        //
//    MMMMMMMMMMMWWNKxolc::::::::::::::::::cldxddoc:o0d::dOl:codxxol:::::::::::::::::::clokKNWMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMWWN0kkxoooc:::::::::::::::clddolooccooloddlc:::::::::::::::coooxkkKNWWMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMWWWNKK0OOkxdddooololclllooc::::coollcclllooodddxkkO00KNWWWMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK0OkxdooolllldxOdllxkxollllooodkkOKKNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMWNX0kxdlcc::::::::lxOXWW0xkKWWXOdl::::::::ccodxk0XNMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMWKkoc:::::::::::lokKNWMMMMKkOXWMMMWX0xoc::::::::::cldOXWMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMWNOdc:::::::ccloxk0XWMMMMMMMMKOKNMMMMMMMWNX0kxocc::::::::lx0NMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMWNK0OxxxdxkkO00KXXWWMMMMMMMMMMMMX0KNMMMMMMMMMMMMWNXKK0OOkkxxxxxO0KNWMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMWNNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMNXNWMMMMMMMMMMMMMMMMMMMMMMMWMMWWNNNWMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW        //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HM420 is ERC721Creator {
    constructor() ERC721Creator("Haze Mist", "HM420") {}
}