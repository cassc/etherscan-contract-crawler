// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crossmint
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNWMMMMMM    //
//    MMMMMXkxxOKNNXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkolodc;'lXMMMMMM    //
//    MMMMMO,...':c,,:d000NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkoodl,........cXMMMMMM    //
//    MMMMMNd.............;d0KKWMMMMMMMMMMMMMMMMMMMMMMWNOc'.............;0WMMMMMM    //
//    MMMMMWx...............'',lKWMMMMMMMMMMMMMMMMMMXxc;................lKMMMMMMM    //
//    MMMMMM0;........''........,x0KWMMMMMMMMMMMMMNk;.............'.....:KMMMMMMM    //
//    MMMMMMW0c.......':lc'.......''oXMMMMMMMMMWKOo'............:l,....cKMMMMMMMM    //
//    MMMMMMMWk'........,oxd:........:0WMMMMMMWk,.............;dd,....'kWMMMMMMMM    //
//    MMMMMMMWO;..........,oOkl'......:KMMMMMWk'............;dkl.....'dNMMMMMMMMM    //
//    MMMMMMMMW0c...........,o00o,.....:dKMMMK:...........;d0d,.....'xNMMMMMMMMMM    //
//    MMMMMMMMMMNx,...........,oKKd,.....lXMNd'.........;d0k:......'lKMMMMMMMMMMM    //
//    MMMMMMMMMMMWk,............,dKKd,...'xXd'........;x0Oc......;o0WMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKd:............;xXKo'..,c,.......:xKOc.......;OWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNO:............:kX0c........'ckKOc.......;o0WMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKd:'...........c0Xx,....;o0Kx:.....;lx0NMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKOxdo:'......,dX0dllOK0o,....,:dXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWKkoc;'...;OWWWXx:'...,coONMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWOl;'....'lkK0xdOKd'.......,codk0XWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWXOdc'.....;dKXkc'...lKO:............,lONMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWXkc'.......:kXKd;.......;kKx,............,dXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWKl........cOX0o,.....,l:'..cO0o'............,lONMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWXxc'......:OXOl'.......cOk:...'lO0l'.............oXMMMMMMMMMMM    //
//    MMMMMMMMMMMNx;.......;kKOc.........cKWNx'....'lOOl'............lKWMMMMMMMMM    //
//    MMMMMMMMMMM0:......'d0kc..........'kMMMNOl'....'lOOl'...........,xNMMMMMMMM    //
//    MMMMMMMMMWO:......ckk:............lXMMMMMNo.......ckko,...........dWMMMMMMM    //
//    MMMMMMMMMK:.....,ox:.............lXMMMMMMMXo........;dko;.........oNMMMMMMM    //
//    MMMMMMMMNd,....,c:............:xONMMMMMMMMMNk:''......'col;.......,kNMMMMMM    //
//    MMMMMMMWd......'............'oXMMMMMMMMMMMMMMNKOc........,:;.......'xWMMMMM    //
//    MMMMMMMNx'...............,:o0WMMMMMMMMMMMMMMMMMMNx:,,...............lXMMMMM    //
//    MMMMMMMXo..............;dKWWMMMMMMMMMMMMMMMMMMMMMMNKKOl,''..........cKMMMMM    //
//    MMMMMMWx.........:ooldONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKKkl;;cl,....dWMMMM    //
//    MMMMMMWx'';locld0NMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNWN0kkkKWMMMM    //
//    MMMMMMMNKXNMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract CRSMT is ERC721Creator {
    constructor() ERC721Creator("Crossmint", "CRSMT") {}
}