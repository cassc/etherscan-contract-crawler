// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peepo Luv
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    xONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK0OodKWMMMMMMMMMMMMMMMMMM    //
//    0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX00WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdd0WMMMMMMMMMMMMMMMMM    //
//    0XWWNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dlxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0olkNMMMMMMMMMMMMMMMM    //
//    KNMWWWWMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdxKWMMMMMMMMMMMMMMM    //
//    MMMMWX0XWNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMWWWMMMMMMMMWMMMMMMMMMMMMMMMMMMWWWWXdlokXMMMMMMMMMMMMMW    //
//    MMMMWNXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMWXOxxxONWNOoxXWWNKXNWWWWWMMMMMMMMMMMMMMMMWNWXxccxXWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNWMMNOo:;;:d00kc.'oKX0ocldxkO0XWMMMMMMMMMMMMMMWWXklllx0XMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMWN0dcclolc:ld:..;kKOxc,,,;coxKWMMMMMMMMMMMMMMMWXKOdd0NMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWWMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMWKxo::lol,':do,.,oO0Oxc;,,,;:okKWWMMMMMMMMMMMWNXXKkoONMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0KWMWKxl:,,,;;,,:c;...,coooolc:;;;;cxXWMMMMMMMMMMMWWXKx:cx0WMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMWWNNWWKxoc,'...........,cdkkxdoool:,,;o0NMMMMMMWWMMMMN0d'.;dXMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMMWNK0Oxolc;'....'lx0K0kdlllolc;,',:dKWMMMMNK0XWMMMWNOodkXWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMWWK0XWMMMMMMMMMMWMMMWXKKXXXKOd:'..,okOOkllx00Oxc,..';oONMMMWXKOkXMMMWKkdokNMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xooooc;;cox0NWMMMMMMWXKKXKOO000kdo;..'clcc:'':olc;....';cxXWMWX00OkXMMMWKdllkNMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWWWWNOdc;cdddl,',;lxKNMMMMNkodOOdokOx:;c;..';,..............';cd0NWWX0OkKWMMWWX000KWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWWMMWMMMMWWNNWWWNXKK0d;,oXWMMWKOkdoooc:;,,:;..',...      .....',:ldkKNN0xoxXMMMMMNKkdx0NMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:cOWMMMWXd:,'....,;'..,,'..       ...',;cloxOKKOxx0WMMMMMWNKOkxkXMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0ooKWMMMNk:'.....,:,.';,''..........',;:ccldkOKXNWWWWNWMMWMMWXOkk0NMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMWWWWWWMMMMNOokXWWWKd;'''',cddlll:,''........',;;;::loxk0NWMWNKKNMMMMWNXXXKOKMMMMMMM    //
//    MMMMMMMMMMMMMMNK00XWMMMMMMMWN0kdddxk0Kkdodxk0NWW0ooOOdoO0dc:;::looc:;'''',,,;;,''',,,,;:coxOKNWWX0O0XWMMWNOkXMWNWMMMMMMM    //
//    MMMMMMMMMMMWWXkc,,oXMMMMMMWOc.......,;'....';lONWX000OddKXkolloddl:;,;;::clooo:'''',,,;:ldk0XNNK0OOOKXNN0dc:kWMMMMMMMMMM    //
//    MMMMMMMMMMWKOkdl;cOWMMMMMW0:.,looc,,,,;::oxxl;c0WMWNWNKOKWNOxddxkkxoc:::clool;''',,;;;:cox0XNX0OOOOOO000koccdOKNWWWMMMMM    //
//    MMMMMMMMMMWOlll::xNMMMMMMNk;;d0kxxc'.';;cdk0OlcOWMMMMWXkOXX0kxoodkkdc:,,;::,...',;;::cldOKXXKOOOOOOOOOOOOkkxdollloxOKNWM    //
//    MMMMMMMMMMWk:cc,:0WMMMMMMNk,.;lc::,.....,;ldl,;kWMMMMMNkxkkxxxdlclddolc:;,.....';:cloxOKNNKOOOOOOOOOOOOOOOOkkkkxol:::cxK    //
//    MMMMMMMMMMWKoc:ckNMMMMMMMW0;. .............'..lKWMMMMMWKKNNNXK0xl:::cc:,'......,coxO0XNNX0kkOOOOOOOOOOkkkkkkkkkkkkkxdl:;    //
//    MMMMMMMMMMMNd,c0WMMMMMMMMMNk;.............':ld0WMMMMMMWXNWWNNX0Okl;''........,cdOKXNWNX0kkkOkOOOOOOOOkkxl:codxkkkkkkkkxl    //
//    MMMMMMMMMMMMXOOXWMMMMMMMMMMNKkc..  .'.''...c0NWMMMMMMWWNNWNK000KK0dc:;;;;:coxOKXWWWWN0OkkkkkkOkkkkkOkkkxo:;,;;;cldxkkkkk    //
//    MMMMMMMMMMMMMMWWMMMMMMMMMMMWN0c.    .......'xXWMMMMMWXXNNNK000K0KOocccccdOKXNNNNNNXKOkkkkkkkkkkkOkkkkkxlldddol:;;,;;:ldx    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWKl.           ..:ONMMMMWKdlkNWWNXKOxl;';coolcldOKNXK0xdxkkkkkkkkkkkkkkkkkkxoc:;,:cloddoc;,,;    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWO:...        ..':xNMMMMWXxd0WWW0ko;.. ..;dkkkdlccodxxoldxxxxkkkkkkkkkkkkkkkkxdc;clc:ccloddl:    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWKl..........'',;lOWMMMMMWNWMMWKxo:...'::cxkkkkkkdlc::;;;;;;lxkkkkkkkkkxxxkkkkkkkkxdl:c;',::;    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNO:...'''',,,;;:dKWMMMMMMMMMMWN0kl'..cxkkkkkkkkkkkkxxdoooodxkkkxxxxxdl;;okkkkkkxdl:..';'....    //
//    MMMMMMMMMMMWWNWWWWMMMMMMMMMMMW0o;'......';oOXWMMMMMMMMMMMMWNXOoloxkkkkkkkOkkkkkkkkkkkkkkkkxc,,,'...'dkkkkkkd;.    .....:    //
//    MMMMMMMMNKkO0O00KXWMMMMMMMMMMMWNX0xoc::ok0NWMMMMMMMMMMWWWNNXXXKOkkkkkkkkkkkkkkkkkkkkkkkkkkkdc'.   .;xkkkkkkdc.      .;cc    //
//    MMMMMMNOoclxkOOOOKNWWMMMMMMMMMMMWWWWNXNNWWMMMMMMMMWWWWN0OO0OOO00OOkkkkOkOOkkkkkkkkkkkkkkkkkkkd:.  .ckkkkkxo:'.    ..:ol'    //
//    MMMMMXx:cdxkkkkkkO0KXNNWWWWWWMMMMMMMMMMMMMMMMMMMMWWXK00kxxkkkkkOOOOOkOkOOOOOOOkkOOOkkkkkkkkkkkxo:.,okkkkxl,''''...'cdl,,    //
//    MMMMWOooxxxxxxxxxxkOO0OOOO00KNWWWWWWWWWWWWWWNXXX0kxkkkkkkkkkxkkkkOOOkOOkkkkkkkkkkkkkkkkkkkkkkkkkxxxkkkkkkdcclddo;,cdl,,o    //
//    MMMMNOxxxxxxxxxdxxxxxxdoxkxooOOxx0XXXXXXKKKK0OOOd:;cxkkkxxxxxxxxkkOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxl,;do,'lx    //
//    MMMWXOxxxxxxxxxxkkxxxxxxxkkkkkxooxkOOOOOOOOOOOOOkkkkkkkxdddddddxxkkOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxc..:o;'cxk    //
//    MMMWXkxxxxxxxxxxkkkkkkOOOkkkOkkkkkkOOOkOOOOOOOOOOOOOOOkxdddddddxxkkOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxd:..ll';xkk    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PEEPO is ERC1155Creator {
    constructor() ERC1155Creator("Peepo Luv", "PEEPO") {}
}