// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ledger x Killer Acid, Deadfellaz Infected S2
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//     ██ ▄█▀ ██▓ ██▓     ██▓    ▓█████  ██▀███      ▄▄▄       ▄████▄   ██▓▓█████▄     //
//     ██▄█▒ ▓██▒▓██▒    ▓██▒    ▓█   ▀ ▓██ ▒ ██▒   ▒████▄    ▒██▀ ▀█  ▓██▒▒██▀ ██▌    //
//    ▓███▄░ ▒██▒▒██░    ▒██░    ▒███   ▓██ ░▄█ ▒   ▒██  ▀█▄  ▒▓█    ▄ ▒██▒░██   █▌    //
//    ▓██ █▄ ░██░▒██░    ▒██░    ▒▓█  ▄ ▒██▀▀█▄     ░██▄▄▄▄██ ▒▓▓▄ ▄██▒░██░░▓█▄   ▌    //
//    ▒██▒ █▄░██░░██████▒░██████▒░▒████▒░██▓ ▒██▒    ▓█   ▓██▒▒ ▓███▀ ░░██░░▒████▓     //
//    ▒ ▒▒ ▓▒░▓  ░ ▒░▓  ░░ ▒░▓  ░░░ ▒░ ░░ ▒▓ ░▒▓░    ▒▒   ▓▒█░░ ░▒ ▒  ░░▓   ▒▒▓  ▒     //
//    ░ ░▒ ▒░ ▒ ░░ ░ ▒  ░░ ░ ▒  ░ ░ ░  ░  ░▒ ░ ▒░     ▒   ▒▒ ░  ░  ▒    ▒ ░ ░ ▒  ▒     //
//    ░ ░░ ░  ▒ ░  ░ ░     ░ ░      ░     ░░   ░      ░   ▒   ░         ▒ ░ ░ ░  ░     //
//    ░  ░    ░      ░  ░    ░  ░   ░  ░   ░              ░  ░░ ░       ░     ░        //
//                                                            ░             ░          //
//     ██▓ ███▄    █   █████▒▓█████  ▄████▄  ▄▄▄█████▓▓█████ ▓█████▄                   //
//    ▓██▒ ██ ▀█   █ ▓██   ▒ ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓█   ▀ ▒██▀ ██▌                  //
//    ▒██▒▓██  ▀█ ██▒▒████ ░ ▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▒███   ░██   █▌                  //
//    ░██░▓██▒  ▐▌██▒░▓█▒  ░ ▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒▓█  ▄ ░▓█▄   ▌                  //
//    ░██░▒██░   ▓██░░▒█░    ░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░▒████▒░▒████▓                   //
//    ░▓  ░ ▒░   ▒ ▒  ▒ ░    ░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░░ ▒░ ░ ▒▒▓  ▒                   //
//     ▒ ░░ ░░   ░ ▒░ ░       ░ ░  ░  ░  ▒       ░     ░ ░  ░ ░ ▒  ▒                   //
//     ▒ ░   ░   ░ ░  ░ ░       ░   ░          ░         ░    ░ ░  ░                   //
//     ░           ░            ░  ░░ ░                  ░  ░   ░                      //
//                                  ░                         ░                        //
//     ███▄ ▄███▓▓██   ██▓    ██▓    ▓█████ ▓█████▄   ▄████ ▓█████  ██▀███             //
//    ▓██▒▀█▀ ██▒ ▒██  ██▒   ▓██▒    ▓█   ▀ ▒██▀ ██▌ ██▒ ▀█▒▓█   ▀ ▓██ ▒ ██▒           //
//    ▓██    ▓██░  ▒██ ██░   ▒██░    ▒███   ░██   █▌▒██░▄▄▄░▒███   ▓██ ░▄█ ▒           //
//    ▒██    ▒██   ░ ▐██▓░   ▒██░    ▒▓█  ▄ ░▓█▄   ▌░▓█  ██▓▒▓█  ▄ ▒██▀▀█▄             //
//    ▒██▒   ░██▒  ░ ██▒▓░   ░██████▒░▒████▒░▒████▓ ░▒▓███▀▒░▒████▒░██▓ ▒██▒           //
//    ░ ▒░   ░  ░   ██▒▒▒    ░ ▒░▓  ░░░ ▒░ ░ ▒▒▓  ▒  ░▒   ▒ ░░ ▒░ ░░ ▒▓ ░▒▓░           //
//    ░  ░      ░ ▓██ ░▒░    ░ ░ ▒  ░ ░ ░  ░ ░ ▒  ▒   ░   ░  ░ ░  ░  ░▒ ░ ▒░           //
//    ░      ░    ▒ ▒ ░░       ░ ░      ░    ░ ░  ░ ░ ░   ░    ░     ░░   ░            //
//           ░    ░ ░            ░  ░   ░  ░   ░          ░    ░  ░   ░                //
//                ░ ░                        ░                                         //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract KDEAD is ERC1155Creator {
    constructor() ERC1155Creator() {}
}