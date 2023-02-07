// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - Rainbow Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXko:;;coOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx,.........;dKWMMMMMMMWNNNWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWWWMMMMMMMNk:..'coddoc,...,o0NNXKOxl:::ld0NWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWN0kdoddxO0KKOc. .:dkkkkkkxdl,...;;'..........:kNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMXx:.........''...;oxkkkkkkkkkkxo:,''',:cloddo:. .dNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMNo. .;loollc:;;;coxkkkkkkkkkkkkkkkxxxxxkkkkkkkxo' ,OWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMW0, .lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkx:..lXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNx..;dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxo, 'xXWWMMMMMMMMMMMMM    //
//    MMMMMMMMMMXo..cxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxl'..;cdkOKXWMMMMMMMM    //
//    MMMMMMMMWNk, .lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxo:,......,lONMMMMMM    //
//    MMMMWX0xl;. .:dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxdoc:,...lKWMMMM    //
//    MWXxc,....,:lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxo;..cXMMMM    //
//    WO:. .,codxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxl. ,OWMMM    //
//    K:..:dxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOKXK0Okkkkkkkkkkkkkkxc. :KWMMM    //
//    O'.'okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOKNWMWWNKOkkkkkkkkkkkko' .xWMMMM    //
//    K:..cxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk0XWMMMMMMNKkkkkkkkkkkkx:. cXMMMMM    //
//    WO;..cxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOKNWMMMMMMWKOkkkkkkkkkkkd,..dNMMMMM    //
//    MWk, .cxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk0XWMMMMMMWX0kkkkkkkkkkkkkxc. ,xXWMMM    //
//    MMNx. 'okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOKWMMMMMMWNKOkkkkkkkkkkkkkkkxl'..:ONMM    //
//    MMXd. 'oxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOO0NWMMMMMMWX0kkkkkkkkkkkkkkkkkkxdc'..lKW    //
//    WKo. .lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk0XNWMMMMMMWNKOkkkkkkkkkkkkkkkkkkkkkxd;..lX    //
//    O:..,oxkkkkkkkkkkkkkkkkOKXX0OkkkkkkkOKNWMMMMMMMNKOkkkkkkkkkkkkkkkkkkkkkkkkkl. .k    //
//    , .:dkkkkkkkkkkkkkkkkk0XWMMWNX0Okkk0XWMMMMMMMWN0kkkkkkkkkkkkkkkkkkkkkkkkkkd:. ,0    //
//      ,dkkkkkkkkkkkkkkkkk0NWMMMMMMWNXKXNWMMMMMMMNKOkkkkkkkkkkkkkkkkkkkkkkkkxdc'..;OW    //
//    . .lxkkkkkkkkkkkkkkkkOKNWMMMMMMMMMMMMMMMMMWX0kkkkkkkkkkkkkkkkkkkkkkkkxo:...,dKWM    //
//    o...:odxkkkkkkkkkkkkkkkO0XNWMMMMMMMMMMMWWNKOkkkkkkkkkkkkkkkkkkkkkkkkd:...:xXWMMM    //
//    NOc...';ldxkkkkkkkkkkkkkkkO0KNWWMMMMMMWX0Okkkkkkkkkkkkkkkkkkkkkkkkkkl. ,kNWMMMMM    //
//    MMN0d:'..'cxkkkkkkkkkkkkkkkkkO0KNWMMWX0kkkkkkkkkkkkkkkkkkkkkkkkkkkkkl..:KMMMMMMM    //
//    MMMMWNKd' .cxkkkkkkkkkkkkkkkkkkkO0KXKOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkd,.'kWMMMMMM    //
//    MMMMMMMXl..:xkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkx:..oNMMMMMM    //
//    MMMMMMMXl..:xkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxc..lXMMMMMM    //
//    MMMMMMMXl..:xkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxdc. .xWMMMMMM    //
//    MMMMMMMNd. ,okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdolc::;,,...,xNMMMMMMM    //
//    MMMMMMMMKc..'coddddddddxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdc'......'';cdKWMMMMMMMM    //
//    MMMMMMMMWXx;...........,cdkkkkkkkkkkkkkkkkkkkkkkkkkkkkkx:. ,ok00KXXNWMMMMMMMMMMM    //
//    MMMMMMMMMMWXOdlc:cccc:'..;oxkkkkkkkkkkkxxxxxxkkkkkkkkkxc. ,OWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWWWWWWWNKl. ,oxkkkkkkxxoc,''',:ldxxxkkkxl. 'kWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNd'..cdxxxxoc,....''....':cllc;. 'xNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWO:...,;,'...,lk0KXKko:'......'cONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWXkc,....;lOXWMMMMMMWNKOxddxOKWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0OO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract CHECK is ERC721Creator {
    constructor() ERC721Creator("Checks - Rainbow Edition", "CHECK") {}
}