// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Not Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMWWNXKKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXKXNWMMM    //
//    MMMMMMMMMMMMMMMMMMMWNKOxoldONMMMMMMMMMMMMMMMMMWNKOkxolcc:cox0NMMMMMMMMMMMMMMMMMMMMMMWNKOxdlcc:coxKWM    //
//    MMMMMMMMMMMMMMMWNKOdl:;;;;;ckNMMMMMMMMMMMMWNKkdl:;;;;;;;;;;;:dXWMMMMMMMMMMMMMMMMMWX0xoc;;;;;;;;;;cxN    //
//    MMMMMMMMMMMMWX0xo:;;;;;;;;;;lKMMMMMMMMMWNKko:;;;;;;;;;;;;;;;:oKWMMMMMMMMMMMMMWWXOdc;;;;;;;;;;;;;;cxX    //
//    MMMMMMMMMWXOdl:;;;;;;;;;;;;;oKMMMMMMMWKko:;;;;;;;;;;;;;;;;;;:lONMMMMMMMMMMMWN0dc;;;;;;;;;;;;;:;;;:lO    //
//    MMMMMMMMNkc;;;;:loc;;;;;;;;l0WMMMMMN0dc;;;;;;;;;;;;;;:oxxo:;;;cOWMMMMMMMMWXko:;;;;;;;;;:c:lxO0xc;;;c    //
//    MMMMMMMM0lcldkOK0xc;;;;;;;l0WMMMMN0o:;;;;;;;;;:ldkOxxKNWWNx:;;;dXMMMMMMMNOl;;;;;;;;;cokKKKXWMMNk:;;;    //
//    MMMMMMMMNKKNWWW0o:;;;;;;;oKWMMMWKd:;;;;;;;;;cd0XWMMWMMMMMWOc;;;oXMMMMMW0o:;;;;;;;:okKNWMMMMMMMWk:;;;    //
//    MMMMMMMMMMMMMNkc;;;;;;;:dXWMMMNkc;;;;;;;;:okXWMMMMMMMMMMMNk:;;;dXMMMWXkc;;;;;;;:d0NWMMMMMMMMMMXo;;;:    //
//    MMMMMMMMMMMWKd:;;;;;;;:xNMMMWKd:;;;;;;;:o0NWMMMMMMMMMMMMW0l;;;:xNMMWKd:;;;;;;:d0NMMMMMMMMMMMMXx:;;;l    //
//    MMMMMMMMMMNOl;;;;;;;;ckNMMMW0l;;;;;;;:o0NMMMMMMMMMMMMMMW0l;;;;l0WMW0l;;;;;;;lONMMMMMMMMMMMMWXd:;;;:k    //
//    MMMMMMMMWXx:;;;;;;;;lOWMMMWOc;;;;;;;ckNWMMMMMMMMMMMMMMW0l;;;;:xNMW0l;;;;;;:xXWMMMMMMMMMMMMWKo:;;;;dX    //
//    MMMMMMMWKo:;;;;;;;;o0WMMMWOc;;;;;;;o0WMMMMMMMMMMMMMMWNkc;;;;;oKWWKo;;;;;;ckNMMMMMMMMMMMMMNOl;;;;;l0W    //
//    MMMMMMNOl;;;;;;;;:oKWMMMW0l;;;;;;:dXWMMMMMMMMMMMMMMWKd:;;;;;l0WWXd:;;;;;ckNMMMMMMMMMMMMWKd:;;;;;l0WM    //
//    MMMMMXxc;;;;;;;;:xXWMMMMXd;;;;;;:dXWMMMMMMMMMMMMMNXOl;;;;;;l0WMWOc;;;;;:xNMMMMMMMMMMMWXkl;;;;;;l0WMM    //
//    MMMWXd:;;;;;;;;ckNMMMMMWOc;;;;;;oKWMMMMMMMMMMMMN0dc:;;;;;;l0WMMNx;;;;;;oKMMMMMMMMMMWXkl:;;;;;:dKWMMM    //
//    MMWKo;;;;;;;;;ckNMMMMMMNd;;;;;;:kWMMMMMMMMMMWN0d:;;;;;;;:dKWMMMXd;;;;;;xNMMMMMMMMWKxc;;;;;;;ckNMMMMM    //
//    MWXo;;;;;;;;;lONMMMMMMMXo;;;;;;lKWMMMMMMMMWNOo:;;;;;;;;ckNMMMMMNd;;;;;:xNMMMMMWN0dc;;;;;;;cxKWMMMMMM    //
//    MXd:;;;;;;;;l0WMMMMMMMMXo;;;;;;oXWMMMMMMWXkl:;;;;;;;;:dKWMMMMMMWk:;;;;;oKWWWX0xo:;;;;;;;cdKWMMMMMMMM    //
//    Nk:;;;;;;;;l0WMMMMMMMMMNx;;;;;;l0WMMWWXOdc;;;;;;;;;:d0NMMMMMMMMMXd:;;;;:oxxoc:;;;;;;;:lkKWMMMMMMMMMM    //
//    0l;;;;;;;;l0WMMMMMMMMMMWKl;;;;;;oO0Oxoc;;;;;;;;:cxk0NMMMMMMMMMMMMXxc;;;;;;;;;;;;;;cox0NWMMMMMMMMMMMM    //
//    d;;;;;;;;cOWMMMMMMMMMMMMW0o;;;;;;;;;;;;;;;;;:cdOXWMMMMMMMMMMMMMMMMWKxl:;;;;::cldxOKNWMMMMMMMMMMMMMMM    //
//    :;;;;;;;:kNMMMMMMMMMMMMMMWXxl;;;;;;;;;;;:cox0XWMMMMMMMMMMMMMMMMMMMMMWNK0OO00KXNWMMMMMMMMMMMMMMMMMMMM    //
//    ;;;;;;;;dXMMMMMMMMMMMMMMMMMWXOxdoooodxkOKXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    c;;;;;;:OWMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNXXXKKKK000000000KKKKKXXXXNNNWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    0xl:;;;cOWMMMMMMMMMMMMMMMMWWNXK0Okxddollccc::::::::;;;:::::::::ccclllooddxxkO0KXXNWWMMMMMMMMMMMMMMMM    //
//    MWN0kdll0WMMMMMMMMMMMWNK0kdolc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::cloxk0KNWMMMMMMMMMMM    //
//    MMMMMWNNWMMMMMMMWNKOxol:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:lx0NMMMMMMMMM    //
//    MMMMMMMMMMMMWNKkdl:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;:xNMMMMMMMM    //
//    MMMMMMMMMMWKko:;;;;;;;;;;;;;;;;;;;:ccloodxxkkkOOOO000000000000000OOOkkkxxddoolcc::;;;;;;;:dXMMMMMMMM    //
//    MMMMMMMMWKdc;;;;;;;;;;;;;;:clodkO0KXNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWNNXK0OkxxddxOXWMMMMMMMM    //
//    MMMMMMMW0l;;;;;;;;;;;;cldk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMNx:;;;;;;;;;cxOKNWMMMMMMMMMMMMMMMMWWWNNNXXXKKK000OOOOOOkkkkkkkkkkkkOOOOO00KKXXNNWWMMMMMMMMMMM    //
//    MMMMMMMWKo:;;;;;;:lOWMMMMMMMMMMWWNXKK0Okxxdoollcc:::::;;;;;;;;;;;;;;;;;;;;;;;;;;:::ccllodxO0XNWMMMMM    //
//    MMMMMMMMMN0kxddxk0XWMMMMWWNK0Oxdolc::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:cokXWMMM    //
//    MMMMMMMMMMMMMMMMMMMWNX0kxolc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;oXMMM    //
//    MMMMMMMMMMMMMMMWX0kdlc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::ccccccccc::::::;;;;;;;;;;;;:xXMMM    //
//    MMMMMMMMMMMWX0koc:;;;;;;;;;;;;;;;;;;;;;;;;::cllodddxxkkkOOO000KKKKKXXXXXXXXXKKKKK00OOkkkxxxxxkKWMMMM    //
//    MMMMMMMWNKkdc:;;;;;;;;;;;;;;;;;;;:clodxkO00KXNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMWXOoc;;;;;;;;;;;;;;;;:codxO0KXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMWXkl;;;;;;;;;;;;;;:loxOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMWKo;;;;;;;;;;;;:cdk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMWk:;;;;;;;;;;:d0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMWKo;;;;;;;;;cxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMWXOxoooodxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NART is ERC721Creator {
    constructor() ERC721Creator("Not Art", "NART") {}
}