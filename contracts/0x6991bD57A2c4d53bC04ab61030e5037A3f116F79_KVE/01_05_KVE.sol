// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ke Visuals Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNOdc::lx0WMMMXOoccldk0NMWKxl:cdKOoooool:cOWMMMMMMM    //
//    MMMMMMMMMMMNO'  :KWMMMMWk'.;kXNWMMMWXl  .kX00000x..kMMMMMMMM    //
//    MMMMMMMMMMMMX;  cNMMMWKl';kNMMMMMMMMMx. .OMMMMMMWdlXMMMMMMMM    //
//    MMMMMMMMMMMMX;  lNMMXd,,xNMMMMMMMMMMMx. .OMMMMMMMWNWMMMMMMMM    //
//    MMMMMMMMMMMMX;  lNNk;,oXMMMMMMMMMMMMMx. .OMMMMWOOWMMMMMMMMMM    //
//    MMMMMMMMMMMMX;  ck:.;0WMMMMMMMMMMMMMMx. .lkkkko'lNMMMMMMMMMM    //
//    MMMMMMMMMMMMX;  :o. .oXMMMMMMMMMMMMMMx. .:ddddc.lNMMMMMMMMMM    //
//    MMMMMMMMMMMMX;  lXk'  ;OWMMMMMMMMMMMMx. .OMMMMNxkWMMMMMMMMMM    //
//    MMMMMMMMMMMMX;  lWMKc. .oXMMMMMMMMMMMx. .OMMMMMWNNNWMMMMMMMM    //
//    MMMMMMMMMMMMX;  lNMMNx'  ,OWXkxxOWMMMx. .OMMMMMWOocoXMMMMMMM    //
//    MMMMMMMMMMMMX;  cNMMMMK:  .lkdd:cXMMMx. .OMMMMMMKd';XMMMMMMM    //
//    MMMMMMMMMMNOo'  ,d0WMMMNx,..,oxclXWKx:. .:lllllll'.lNMMMMMMM    //
//    MMMMMMMMMMN0OOOOOOKWMMMMMNK0OOO0KWWX0OOOOOOOOOOOOO0XWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMXKXKNMMNXMMWNNWMMWNNWWMMMWXNWMMKKMMWNNWMMMMMMMMM    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract KVE is ERC1155Creator {
    constructor() ERC1155Creator("Ke Visuals Editions", "KVE") {}
}