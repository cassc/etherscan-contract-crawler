// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SyiidNFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ▒▒╢╢╢╢╢╢╢╣╢╣╢╣╣╣▒▒▒▒▒▒▒▒▒╢╢╣╣╣╢╢╢╢╢╢╢╢╢╢╢╣╢╣╢╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣▒╣╣▒▒▒▒▒    //
//        ▒▒╢╫╣╣╢╢╢╢╣╢╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣╣╣╣╣╢╣╣╣╣╣╣╣╢╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢▒╣╣╢╣╣╣╢╣╢╢╢╢╢    //
//        ▒▒╢╢▓▓▓╣╣╢╢╢╢╢╢╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▀▒▒▒▒▒▒▒▒▒▒▒▒╣╣╣╢╣╣╢╢╢╢╢╢╢╢╢╢╢╢    //
//        ▒▒▒╢╫▓▓▓▓▓▓▓╣╣╢╢╢╢╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐▒▒▒▒▌▒▒▒▒▒▒▒╣╣╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢    //
//        ▒▒▒╢╫▓▓▓▓▓▓▓▓╣▓▓▓▓▓╢╢╣╣▒▒▒▒▒▒▄▄▄▄▄▄▄▄▄▄▄▄▄▒▒▒▒▒▀▒▒▓▒▒▒▒▒▒╣╣╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╣╣╣╢    //
//        ▒▒╢╢╫▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓╢███▀▀▀░░░''````'''░▀▀▀▀███▌▒▒▒╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╣▒▒Ñ    //
//        ▒▒╢╢╫▓▓▓▓▓╣╣╣▒▀▀▒▓▒╢▄█▀▀░` ▐███▄▄▄▄▄≡¿≡╖,,    ░░░▀▀██▒╢╣╣╢╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╣╢╣     //
//        ▒▒╢╢╫▓▓▓▓╣▒▓▓▒▒█▒╢▒█▀░░░░km▒░░▀▀█████████▄░░▒▒░░░ ,,▄██▄▒╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╣╣╢╣     //
//        ▒▒╢╢╢▓▓▓╣╣╣╢╢╢▒▀▒▒█░░░░░░▒▒▒╢▄▄▓▄▄▄▒▀█████▌░▐██████████▀█▌╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╣╣╢╣     //
//        ▒▒╣╢╫▓▓╣╣╣╢╢╢╢╢╢▒█░░░░░░▒▒▒▒▄██████████▒▀▀▒▒░███████▒▒▒▒░██╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╣╢▒╢     //
//        ▒▒╢╢╫▓▓╣╣╣╢▒▄████▌░░░░░░▒▒▒█▄▄   ███`'▀██▒▒▒▒▀█████████▓▒░█▌▒▒╢╢╢╣╢╢╢╢╢╢╢╢╢╢╢▒╢     //
//        ▒▒╣╢╫▓▓╣╣██▀▒▒╓╙╜██░░░░░▒▒▒╢▒██████████▀▒▒▒▒▒▒▒▀█▄▄, █████▐█▒▒▒▒▒╣╢╢╢╢╢╢╢╢╢╢╢▒╣░    //
//        ▒▒╣╢╫▓▓╣██▒█▀▀██▒,██▒░░░░▒▒▒▒▒▒▒▓██▀▀▀███▄░▒▒▒▒▒▄▒███████▀░█▒▒▒▒▒╣╣╣╢╢╢╢╢╢╢╢╢╢╣░    //
//        ▒▒╣╢╫▓▓██▒▄▒▒▒▒▒█▒▒█░░░░░░░░░░░░▒▄▌▀▒█▀▒█▒██████▌▀██████▒░░█▒▒▒▒▒▒▒╢╢╢╢╢╢╢╢╢╢▒▒░    //
//        ▒▒╣╢╫▓╫█▒▒▒▀W▄▒▒▐█▒▒▒▒░░░░░░▒▒▒▒▒▒▒░██▒▀▒▒▒▒▒▒▒▒▀▐█░▒▒▒░▀░▐█▒▒▒▒▒▒▒▒╢╢╢╢╢╢╢╣╢╢▒░    //
//        ▒╫▒▀▀▓██▄▀▀▒▀▀█▓░█░▒▒▒░░▒▒▒▒▒▒░▄███▀▒▒▒▒▒▒▒▒▒▒▒▒▒▀▀▀▀██▄░░█▌▒▒▒▒▒▒▒▒▒▒╢╢╢╢╢╣╢▒▒▒    //
//        ▒╫╣╢╫▓▐█▄▄▄▀░░█▀▀█▌▒▒░▒▒▒▒▒▒▄██▒▒╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣h▒▀███▌▒▒▒▒▒▒▒▒╢╢╣╢╢╢╢╣▒▒╣╣    //
//        ▒╫╣╢▓▓▓█▒▀▀▀░░█▄░░░░▒▒▒▒▒▒░██▒╢╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣╖╙██▒▒▒▒▒▒▒▒╣╣╣╣╢╣╢╢╢╢╢╢    //
//        ▒╢╣╢▓▓▓█░▒░░@▀░██▄░░▒▒▒▒▒▄██╢╢▒▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▒╣╜▀█▒╢╣▒▒▒▒╢╢╣╣╢╢╢╢╢╢╢╣    //
//        ▒╢╣╫▓▓▓██▒░░██▀▀▀▀▀░░▒▒█▌██▌██▀▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▀▀██▒██▌╢╢╣╣╣╢╣╣╢╢╣╢╢╢╢╣╣    //
//        ▒╢╣╫▓▓▓╢█▄░█▀░░░░░░░░░░░█████░░╜▀█▄▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▀▀███▀╢╣╣╣╢╢╢╢╢╢╣╣╢╢╢╢╣    //
//        ╣╢╣╢▓▓▓▓╣██▄▄▄▄▄▄░░░░░░░▒▒▐█░░░░░░▀██▄▒▒▒▒▒▒▒▒▒▒▒▒▒▒▄██▀▒╣╢██▒╢╢╢╢╢╣╣╢╣╣╣╣╢╢╢╢╢╢    //
//        ╢╢╣▓╣╣╣╣╢╢╢▒▒▒████░░░░░░░░░░░░░░░░░░░▀█████████████▀▒▒╣▒▒▒▒▒▒╣╢╢▒▒▒╢╢╢╢╢╢╢╢╢╣╢╬╣    //
//        ▓╣╣╣╢╢╢╢╢╢╢╢╢╢█▌█▌░░░░░░░░░░░░░░░░░░░░░░░░░░⌠░▄██▒▒▒▒▒▒▒▒▒▒▒▒▒╢╣╣╢╢╢╣╢╣╣╣╣╣╢╢╢╢╢    //
//        ╢╢╢╢╢╢╢╢╣╣╢╢╣╢█▌░░░░░░░░░░░░░▐█▄▄░░░░░░░░░░▄██▀▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣╢╣╣╢╣╢╢╢╢╣╢╣╣╢╣    //
//        ╢╢╢╣╣╢╢╣╣╣╣╣╣▒█░░░░░░░░░░░░░░░░░▀▀▀██████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣╢╣╢╢▒╢╢╣╣╢╢╣    //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract Syiid is ERC721Creator {
    constructor() ERC721Creator("SyiidNFT", "Syiid") {}
}