// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vesper 2nd Anniversary
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OkkxdoolllccccccccccllloodxkkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kxdlccccccccccccccccccccccccccccccccccldxk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWX0kxolccccccccccccccccccccccccccccccccccccccccccccloxk0XWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdlccccccccccccccccccccccccccccccccccccccccccccccccccccccldkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWN0koccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclok0NWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNKkoccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccok0NMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWXOdlccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccldOXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWKkoccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccokKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWKxlcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclxKWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWXxlcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclxXWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWNOoccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccoONWMMMMMMMMMMM    //
//    MMMMMMMMMMW0dccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccd0WMMMMMMMMMM    //
//    MMMMMMMMMNklcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclkNMMMMMMMMM    //
//    MMMMMMMWXdccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccxXWMMMMMMM    //
//    MMMMMMW0occcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccco0WMMMMMM    //
//    MMMMMW0occcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccco0WMMMMM    //
//    MMMMW0lccccccccccccccccldkkkkkkkkkkkkkkkkkkkkkkkkdccccccccccccccccccccccccccccoxkkkkkkkkkkkdlccccccccccccccccccccl0WMMMM    //
//    MMMW0occcccccccccccccccdXWWMMMMMMMMMMMMMMMMMMMMMWXxcccccccccccccccccccccccccco0WWMMMMMMMMWWXdccccccccccccccccccccco0WMMM    //
//    MMWKoccccccccccccccccccl0WMMMMMMMMMMMMMMMMMMMMMMMWKocccccccccccccccccccccccccOWMMMMMMMMMMMW0occccccccccccccccccccccoKWMM    //
//    MMXdccccccccccccccccccccdXMMMMMMMMMMMMMMMMMMMMMMMMWOlcccccccccccccccccccccccdXMMMMMMMMMMMMXdccccccccccccccccccccccccdXMM    //
//    MWkcccccccccccccccccccccckNMMMMMMMMMMMMMMMMMMMMMMMMXxccccccccccccccccccccccl0WMMMMMMMMMMMNkcccccccccccccccccccccccccckWM    //
//    MKocccccccccccccccccccccclOWMMMMMMMMMMMMMMMMMMMMMMMWKoccccccccccccccccccccckWMMMMMMMMMMMWOlccccccccccccccccccccccccccoKM    //
//    NxccccccccccccccccccccccccldkkkkkkkkkkkKWMMMMMMMMMMMWkccccccccccccccccccccdXMMMMMMMMMMMMKoccccccccccccccccccccccccccccxN    //
//    KocccccccccccccccccccccccccccccccccccccoKWMMMMMMMMMMMXdccccccccccccccccccl0WMMMMMMMMMMMNxcccccccccccccccccccccccccccccoK    //
//    kcccccccccccccccccccccccccccccccccccccccdXMMMMMMMMMMMM0lccccccccccccccccckNMMMMMMMMMMMWOlcccccccccccccccccccccccccccccck    //
//    dcccccccccccccccccccccccccccccccccccccccckNMMMMMMMMMMMWkccccccccccccccccoXMMMMMMMMMMMWKocccccccccccccccccccccccccccccccd    //
//    occccccccccccccccccccccccccccccccccccccccl0WMMMMMMMMMMMXdccccccccccccccl0WMMMMMMMMMMMXdcccccccccccccccccccccccccccccccco    //
//    lcccccccccccccccccccccccccccccccccccccccccdXMMMMMMMMMMMW0lcccccccccccccxNMMMMMMMMMMMNklccccccccccccccccccccccccccccccccl    //
//    cccccccccccccccccccccccccccccccccccccccccccxNMMMMMMMMMMMNkccccccccccccoKMMMMMMMMMMMW0lcccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccclOWMMMMMMMMMMMXdcccccccccclOWMMMMMMMMMMMXdccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccoKWMMMMMMMMMMW0lcccccccccxNMMMMMMMMMMMNxcccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccxXMMMMMMMMMMMNxccccccccoKMMMMMMMMMMMWOlcccccccccccccccccccccccccccccccccccc    //
//    lcccccccccccccccccccccccccccccccccccccccccccclkWMMMMMMMMMMMKkoccccclOWMMMMMMMMMMWKoccccccccccccccccccccccccccccccccccccl    //
//    occccccccccccccccccccccccccccccccccccccccccccco0WMMMMMMMMMMWWOlccccxNMMMMMMMMMMMNxccccccccccccccccccccccccccccccccccccco    //
//    xccccccccccccccccccccccccccccccccccccccccccccccdXWMMMMMMMMMMMNxcccoKWMMMMMMMMMMWklcccccccccccccccccccccccccccccccccccccx    //
//    OlcccccccccccccccccccccccccccccccccccccccccccccckNMMMMMMMMMMMWKoclkWMMMMMMMMMMW0lccccccccccccccccccccccccccccccccccccclO    //
//    Xdccccccccccccccccccccccccccccccccccccccccccccccl0WMMMMMMMMMMMWOcdXMMMMMMMMMMMXdccccccccccccccccccccccccccccccccccccccdX    //
//    WOcccccccccccccccccccccccccccccccccccccccccccccccoKWMMMMMMMMMMMNOKWMMMMMMMMMMNkcccccccccccccccccccccccccccccccccccccccOW    //
//    MXdcccccccccccccccccccccccccccccccccccccccccccccccxNMMMMMMMMMMMMMMMMMMMMMMMMW0lccccccccccccccccccccccccccccccccccccccdXM    //
//    MW0occcccccccccccccccccccccccccccccccccccccccccccclOWMMMMMMMMMMMMMMMMMMMMMMMKdccccccccccccccccccccccccccccccccccccccl0WM    //
//    MMWOlccccccccccccccccccccccccccccccccccccccccccccccoKWMMMMMMMMMMMMMMMMMMMMMNxcccccccccccccccccccccccccccccccccccccclOWMM    //
//    MMMNxcccccccccccccccccccccccccccccccccccccccccccccccdXMMMMMMMMMMMMMMMMMMMMWOlccccccccccccccccccccccccccccccccccccccxNMMM    //
//    MMMMNxccccccccccccccccccccccccccccccccccccccccccccccckNMMMMMMMMMMMMMMMMMMW0occccccccccccccccccccccccccccccccccccccxXMMMM    //
//    MMMMMXxccccccccccccccccccccccccccccccccccccccccccccccl0WMMMMMMMMMMMMMMMMMXdccccccccccccccccccccccccccccccccccccccxXMMMMM    //
//    MMMMMMNxccccccccccccccccccccccccccccccccccccccccccccccdXMMMMMMMMMMMMMMMMNkccccccccccccccccccccccccccccccccccccccxNMMMMMM    //
//    MMMMMMMNklcccccccccccccccccccccccccccccccccccccccccccccxNMMMMMMMMMMMMMMW0lcccccccccccccccccccccccccccccccccccclkNMMMMMMM    //
//    MMMMMMMMW0occcccccccccccccccccccccccccccccccccccccccccclOWMMMMMMMMMMMMWKocccccccccccccccccccccccccccccccccccco0WMMMMMMMM    //
//    MMMMMMMMMWXxccccccccccccccccccccccccccccccccccccccccccccok0KKKKKKKKKKKOdccccccccccccccccccccccccccccccccccccxXWMMMMMMMMM    //
//    MMMMMMMMMMMNOocccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccco0NMMMMMMMMMMM    //
//    MMMMMMMMMMMMWXklcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclkXWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWKxlcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclxKWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKxlcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclxKWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWXkoccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccoOXWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWN0dlccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccld0NWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWXOdlccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccldOXWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWXOxoccccccccccccccccccccccccccccccccccccccccccccccccccccccccccoxOKWWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kdoccccccccccccccccccccccccccccccccccccccccccccccccccodk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxdlccccccccccccccccccccccccccccccccccccccccldxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0kxdollccccccccccccccccccccccccllodxk0KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXK0OkdoolllcccccccclllodxkO0KXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract V2A is ERC1155Creator {
    constructor() ERC1155Creator("Vesper 2nd Anniversary", "V2A") {}
}