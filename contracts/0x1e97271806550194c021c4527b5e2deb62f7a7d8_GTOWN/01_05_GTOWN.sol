// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ghost Town
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKNNNXXXXXXKKKXXXXNNNXXXNNKK0KNNNNX0KNNX0OXNNNNNXNKdllllloloold00KNNXKNN00kkKNKKKKKKK0KXNNNNXKKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKXXXXXXXXXXXXXXNNNNNNNNXKKKXNNNNNNNX00NNNK0XNNNNNNN0doloolloddx0K0NWWKXNXKKKXNNWWWWWNXK000K0O0KNNXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKKXXXXXXXXXXXXXXXXXXXXXXNNWNNNNXkdxKNX0KNNN0KNNNNNNNXKxoollodddoOX0XWWK0NNNNNXNNNXXXXXXNNNXXKK0kKWXKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWNXXXK0kO00KXXXXNNNWWMWKOKWNNNKkxOKXNKOXNNK0XNNNNNNNW0dloddddolxK0KNWXKWMW0x0NMMWWWNXXXKKKXK0OOKK0XXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKXXXXXX0xxdoxXWWNXXWWWWMNxoONWNXNXXXXXXX00XXX0KNNNNNNNWXxodxddooldKKKNWXKNNKocxXWWWMN0KNWNNXKKKKX0KXKXNXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNNXXKXX00KKKX0xx0XXkco0NWWMWNNWMWNXXNXXXKXXK0XNXK0KKXXNNNWNOdxdoooood0KKNNKOkxoodk0XWWWklxKWNWX00XXO0KKXWNNXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXNNNNNNNX0KNNNNNNX00KOdOXNNWWWWMWXXWNXXNKolkXKOKKK00KK000KNNNOddooodold00KX0xc::::llcoKWWNXNWNNNOod0X0KK0OxdddxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXNNNNNNNNNNN0KNX0OKNNK0KK0KKKXNNNWWW0lckNXXXKOOKXK000K0k0XXK0O0KKOdooodddddO0xdl:ck0OxdoccckNMMWWNNNNXKX00KKKOO00OOKXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXXNWNNNNNNNNXXXK0XN0kdkXK0KKKKOkdx0XNNNN0xx0XKKKKKKK00OOOOOO0K0Okxdddolcllloddoolc::oONN00Kkol:c0XKXNNXXKKXXXNNNNNNNNNWNX00KXXXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK0KXNNNNNNXKKKXKXKKNNXKKXX0KK0XxcclllxKNNNNNNNXK00000OOkkdolooolcc:::cccc::::cc:;;cx0KKKNOcl0Nkc:;lookK000XNNNWNNNNNNNNXK00KNNNNXKKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXXXXXKXXXNKKXNNNNXXXXXXXXXKO0KO0dcllllldKNXKXNXK00Oxolc::;;;;;:::cc:::::::::::::::;:xKNKXWNKKNNxc:;lkO0XXKK00KXKKKKK0000OkKX0OKNNK0K0KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNMWWNWWXXWWWNKKKKXXXXNNNNNXOkddocclccccld0KXKXNXOdl:;:::::;;;;::::::;;;;;;;:::;::::::clxXWWN0OOxdolodxkk0XXK0O0KNNNNNNNNXXN0OkkXK0XKKXXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWXXMWKOO0WMWNXXXXNWWWNNNKddO0xkxc:c:lolcccclx0KXN0dc:::c:;,;;;;;;;;;:::;;;,;;;;;;;:::;;;:::lkOkx0XKOxoldkdoodxkKNNNNNNXXXKKKKKK0KXK0XKKNKOxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXKNWWXKKKNNXXNWMMWKkKWNNKOkkOxc:oxkkoodooddllodkd:::::::;;;;;;;;;,;:::::;;;,;;;,;;;;;;;;;;;:::lxOxollccodxO0OdxKXXNNNWWWWNNXXXKKKK0XK0XOooookNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWKKXKXNXXNXNWWKKWMWX0XWWWNNKxxl:o00KXxllloxkdoo:;::::::;;;;;;;;;;;;;:::::::::;,,,,;;;;;;;;;;;:;;;cllollodk0K0KOkKWWWWWWWNKNWNN0xkK00XKX0oododoOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNKNNNNNXKKNWMXxkNMMMMWWWWWXxodl:xK00K0olllloxxc;:::::;;;::;;;;;;;;;;;;;;;;;;::;,,,,,;;;;;;;,;;;;;;;looolloxOOOkOK0kKWWWKdoONWXd:cx0KX0KkloxxxdxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMXO000KXNXXXXWWWWMMWWMKx0NWN0xxo:xK00KKkollcclc;:::::;,;::::;,,,,,,,,,,,;;;;;;;;;;,,;,,;;;,,,;;;;;;;,;lddolldkkkOKxoONWWN00XWWWKO0K0KXKKkxxoodxd0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMKxdoodd0NXXNXNW0kKWMMNKNWWWXkkd:xXX0000kdlllc;:::::,,;::::;;,,,,'',;,,,;;;::;,;;;;,,;,,,;;,,,,;;,;;;',cxkdloloOXNNNWWWWWWMWWWWWNKK0KXKKOdxxdoookWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNxcloolo0NXNNXN0xKWWWMMMMMWNKkdclOKOxddddol:;::::;,,;::;;;;,,;;,',;;,,:ddc;;:;,;::;,,,,,,,;;,,,,,,;;,',:dOxoldXWNNWX0XWWXkxkKWKdoxO0XKKKkxxdxxokNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0lloloodKNXNXXWMMMMMMMWK0XNX0xocdxxOOkxdkd;;::;,',;;;;;;,,,;,,'',;;;lkOOkxo::;,;::;,',,,,,;;,,',,,,;,,,;oxooOWWNXkoldKW0olo0WKkkOK0XXKXKkxxdxdOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNkolooodONNXNXNNO0NMWMXdd0NNOlldxddddolll:;::;,',;;;;,;,,,;,'',',;;lkOOO00Od::;,;:;,''','',;;,,,,,,,,'',,;:ldx0XXOkO0NMWN00NWW0xxKK0XKKXKkxxddKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNxloooodKNXNXXXdxXMWMWNNWWNOdxxxxxoc:cc:cccc,'';,;;;,,',;,''';lc;:dOOOOOOOOxc;,,;;,,,'','',;,,,,',,;',;,',lxdodONXOxONMNxo0WW0kO0K00XKKXX0kxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkoooldONXNXKWWWMMMWWWNNXOxkOOOOxdlooccodo:'';;,;;,'',,''',:dOd;:xOOOOOOOOOxc,,,;,,,,'''',,;,,,'',;,,;;'.,clc:l0KxdkXWN00XXXKKKKXXK0XKKKXX0XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdoddxXXXXKNNNNNNNNXXXXOx0KKKOdllxd::ldl,';:;,,,,',,''';lkOOkl:dOOOOOOOOOOxc,::;,,,,'',,,,,,,,'',;;,;:,',coc;oKXKXNXXXXXXXNKKKOOXK0KXKK0KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxxxKXKNXXX0kKWXXNXXKKOkKX0kocdkxc,,:l:',;;;;,,'',,'':dOOOOOx:ckOOOkkkkOOOd;cxoc:;;''',',,,,,,'';;;;oo:,;dkccOWWWWWWWNNXXK000kOXNXKKXK0XNXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXXKNNKNNK0XXOKXXXXNXOOkoclxOko;',;:,',;:c;,'',,'':xOOOOOOkc,okkkkkkkkkOx;;dxdl:;,''''',;,,,'.,:;;lxo;'c0xcdKK000000000O00KXNNNNX0OO0KKKXXNWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKK0KNWWWN0KWNNNNNNN0doxO0Ox:'',,;,';cdl;'',,''cxOOOOOOOOo''okOkkkkOOOx:,cccllc:;,',,,;;,,,.';:;;oxc,,odxKXOOKK0KKXNNX0OKXNNXKOkO0KXNNWNKKXNWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWNNNXX0KXKO0KKXXKKXKKKXXNWWNXK0OOOOOkc,''',;,;oxxl;,,;;,:xkkkkOOOOOd,.;dOkOOOOxoc,;lodxxxxxdc,,,;;,;,'.,;:;:do,'cONNK0XNNNNNNNNNNKO0KOkO000O0XX0KXXNNXNWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNNXXXXXNX0XKOOk0NWXKKKXKKXKOxxk0KXKxodxl;,'',,;;cxkxc,,:lllxkkxxddoodxo,.'lkOOOOdccc;;lxkxxxdolc;'',;;;;,'',::;:do,:OX0k0XXXXXXXXKK0000KKKXKOOxok0KNNNNXXXKNWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNXXXNNNNNNXK0XNK00XXXKXXKXKXNOc:clokkooxOx:,,'',,;:okkd:,;odllolcclllcc::,.',lkkkkkolooccolc:cllc;;:,.';,;:;''';::;dk::0X0KXXXXXXXXKKKKKKKKKKKK0OOkkKNXKKXXXNNXXNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWNNXNNNNNNXKKK00XXXKKKKXXXXKKXXXKo:ccc:;cdol:;;,'';,,:okkl;':doclodxkkxoc::,'',:dkkkkxdddxdc'..ckOkxoccl:,;;,::,co:;:;:oc;kKXX00NWWWWWNNXNNNNNXXKKKKK0KNXKKXXXK00KKKNWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWNXXNNNNNXK0KXXXXXKXXXXNNNNNNNKKXXK0xc:c::dkxl:;,,',;,':oxdc,,:dloxkOOOkddl:;;;coxOkkkkxddxkd::ccdxxkxocoko;;,,;;,:ddc::;c:;oKN0oxKWWW0xOXNNNNNNNNNNNKO0XXKKXKOdlloddxOXWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWXXNNXNNXK0KXNXXKKXXNNNNNNNKOO0KX0KXX0Odc::dkdol;,'',;,';loc;,,:lccoodlcclllodxxxkkOOkkkkxxxkOxdodxxxxxdxkOl,,'';;,;ldl:;;;;;xNWNXXWWWW0xOKNNNNXOk0XNNK0XX0XX0dcclooloodONMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMN0O00KKK00KNWNXXXXXNNNNNNNNNOclx0NNKKXXK0koccloxo;,,',;,,;:::;,;;;;;;'.,lkkxocokkxkOOOOOkkkxxxxkkxxkkkOOOOOk:,,,,;;;:loc;;;,,,lddkKXWWWWWNNNNNNNKxdkXNX0KX0KXOdoollooolloxKWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNXK0OOKNNXNWWNNNNNWWWWNX0KNNNXK0XNNNNXKKXXKKkoloxd:,,',;,,,;;;,,;,,;::ccoxkkkdodkkxkOkOOOOkxxxxxxkkkOkOOOOOkc,;:;,;;coodc;;,'',cl:llloxkO0KKXNNNNNXXXNN00XKKXOddooollooolld0NMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWXNNKKOONMWWNXXNNWWWWWMXdcd0NNNNNNNNXKXNXKKXKKKOdc:;,,',;,',;:;,',,;clooodxxkkxxkkkkOOO0KKOxxxxxkkkkkOOOOOOkc',lc;;;;locol;,,',:k0kOxodo::clcoxOKXXXXNNX0KX0X0dlooooooooooox0XWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWNNWWNK0XNNNNXXXNWWMWMWWW0k0NWWNNNNNKdlx0XNKKKXKKK0xo;,'';,,',;;,'',:coxxxxkOOO0OOOOOOO0XKK0kxxxxxkkkkOOOOOx:':dd;,;;llcll;;,'''lkk0NWNXKococclcclddd0XX00XKKXxoolooooooooooxKXNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNXNNNNXXKXXXNNNWMWNKKNMMMMMMWMWWNNNNXkdxKXNNXKKKKKKXOc,'',;,',;;,;,,;:lkOO00000000OOOO0KK0OkkxxxxxkkkkkOOkd:;lxxc,,;oxlcc;,;''''d0OKWWWWNkok000Odddl:cxOOXKKX0oooooooooooooodKNNMMMMMMMMMMMMMM    //
//    MMMMMMMMMWXXNNNNNNNNNNXXWMMNkldKWMWWMMWW0ddOXNXNXXXXNXKXXK00kdl:,,,,;,'',;cl:::;cxOOO00000000OOO00kxxxxxdoddoxOOkkkocoxkkl,,':xxoo:';;,,';OWWWWWWWWNXNNNNNXX0xdoccdKKKXkooooooooooloddxKNNMMMMMMMMMMMMMM    //
//    MMMMMMMMMNXNNWWNNNNNNNNNNNWWXOKWMWWWMMWW0ddONWXXNXXX0dlx00klcccdc,;,,;'',,lxxko::okOOO0000000OOOxddlccodlcoodxkOkxddxkkxl;,,':ddol;,;;,,,oNWWWWWWWWWNNNNNNNNNK0OdoloxKKxooooooooooooloxXXNMMMMMMMMMMMMMM    //
//    MMMMMMMMMXXWWNNNWWWWWNXNNWNNWMMMMNKKNWWWWWNNWWNXXXXXOololcccloO0l,;,,;,',,:okOxc;:dOOOOOOOOOOOOOkxddoddxxxkkkkkOOkkkkkxc:;,,,cocod:,,,',,cxdkNWWWWKxxKXNNNN0k0XNKOxllodooollooooooooookXXNMMMMMMMMMMMMMM    //
//    MMMMMMMMMNXNNWWNK0OO0XWWXNWWNNWMWOclOWWWWWNXXXKOkOxkdllccdkO00Od:,;;,;,',;;cdOko::cdOkOOOOOOOOOOOOOOOOOxxkkkkOOOkkkkkxodx:,,;oc,:lc,,,',,,lk0NWWWWXOOKNNNNXOdOXXKK0xdlclllollooooooooxKXXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMXXWWKOxooolllxKWNXNWNNNWKxdkOkkxddolccclc:clodxOXXK0Od:,,;;,,,'',:lldOdccccdkkOOOOOOOOOOOOOOOkxxxxxxxxxkkkkxxkOx:,,;c:,,;c:,;,,;,;kWWWWWWNNNNNNNNNNXKK0k0Kxol:llllllllllooooOXXXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMNNXkooooddoolcokNWXXWN0kdoc::cooodxkxl;cdkOKXXNNK0XXkc;;,,,,;;'',;colokxclolokOkOOOOOOOOOOOOOxdddodoolloodkOOOOkc,,,,;;,;cc;;;,,,,:xOKNNNNXKXNNNXXKKKKOOKOoolccollllollloookXXXWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWXOolloooooolllldKNKOkdc:lxkOKK0OKWWWX00XNNNNNXKKXKx:;;,,,,;;,.';;:odoxkdcdkoldkkOOOOOO0OkxkxllodddooolldOOOOOOkl,,',;,,:clc;;;,,,,,;xXNN0dokXXK0xxOX0OKOc:c::lllllllllloldKXXNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWX0xolooooooololodxkolloOXNNWWKl:dKWWWWWNNNNNK0KXKx:,,;,,,;:;,',;;;clddoo:cx0koldkOOOOOkdoodoldxxxddoooxkOOOOOkkd;',;;,,:ccc;,;,'',,,cONNKOO000XKkxO0O0Kd:cc::llllollllood0XKNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWX0xoooooooololoololdkOKNWNNWW0olxXWWNNNNXKKKK0Ok:,,,,,,,;;,'';;,;:cddc:;,:dO0xllodkkkxdxkkkxxkxooloxkOOOOOOOkkx:,;,,,,,:cc;,,,,,,,;;;o0XXXK0KKKK00OkKKo::lccolllloollodOKKNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMNXKkdoooooolllcllcclk0OOKXXXN0olldOXXXXKKXK0OKOc,,;,,,,;:;,'';;,,;::ccc;,,;cx00xooddddxkOOOOkxxddxkOOOOOOOOOkko;',,',,,,:c:,;::;;;;;;;:oOKKKK0OOOKK0XXd::lllollllllolokKXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWNXXOdooooolllcllcclox000KKK0oclllld0KKKK00KXO:,;;,,,,;;;,'',;;;;;;;;::;,,,,cdO0OkxxxxxxkOOOOOOOO0OOOOO0OOOkxxc,,,,',;;;;:c::;;;;;;;;;::cdOKX00Odx00KXkc;lxkxolllllodk0XNWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWNNN0xoooollcloc:looookXN0Od::llllcokk0KXNNO:,;;,;;;;:;,,',,,;;:;;;:::;,',,;cdxkOkkkkOOOOOO00000000OOOOOOxxxd:;;'',;:::;;:cc;,,;:c:;;;::::cloxkxkK0KNOc:oxO0kdllodxdx0NNXXNWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNXNXOdoooccll:clllookX0xl::::llllcckXNNNk:,;,,,;;;;;,,,,;;;::::::::::,',,;;lkkkkkkxkkOOOO0OO000OOOOOkkxxkko;;;,',,:c:;,,;;;;;;:::,;c:;::;:ododkOk0XkcdKOOXX00Okxlco0NNNKKXNWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWNNXNNKxdoc:cllolloolodollllc::cccc:l0NNO;'',;;;;;;,,,,,;;;;:,;c::::::,'',,,:dOOOOkkkkkxxxkkkkOOOkkxxxxkkkko;;;,,,,,::;,,,,,,;;,;;;;;::;;;;oKX0kkxxxxk0KXKXXKOxoc:lxXNXKXKKXNNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWNXNNKOOXXOdllloooollcclollcccc:cccccc:dX0:.'',;;;;;,,,,;;,,,:;;:::;::::,'''',;lkOOOOOOOOOOkkkxxxxxxxxkkkkkkko;;;,,,,,;:;;;;,,,,;;;;:;,;::;;,:kXXXXXOdxO0000OkdlllldOXXKXXKKXNNXNWMMMMMMMMMMM    //
//    MMMMMMMMMMWKKWWKOdlkK0K0Oxdoolc:llcc::;;;:::ccccc:cdc.',,,;;,,''',,,,,,,,,;;::c:;;;,'''',:cxOkkkkOkOOOOOkkOkkkkkkkkkkkxxo:;;,,,,,,;;,,,;;;,,,,,;;;::::;,,o0KKOocccccllcccclox0XXXKKKKXXKKXNNXWMMMMMMMMMM    //
//    MMMMMMMMMWXXKKXXK0KKKXKKK0OOkkxdooolcc;,,;;:cccccc:,'',,,,''','',;,,,;,,,;,,;:cc:;;,'''';:cxkkkkkkkkkkkkkkkkkkkkkkkkkxkxo,,,,;;,',::;,,;;;,,;,,,,;;;::;,,l0Oo::cccccc::;;:oOKXXKKKKKXX0KOkXWXXNMMMMMMMMM    //
//    MMMMMMMMWXNWWNXK0KX0KNKK0kOKXKK0Okkxxxdc;,,;:cc::::;;,'',,,,,;,,,,,,,,,,,,,,;;;clc;,'''';;,;lxkkkkkkkkkkkkkkkkkkkkkkkxxl;'',,:;,',:c:;;;;;,;;;;;;;;;;:;,'okc:::::clc:::::::dKKXKKXNXKKK0kOXNK0XWMMMMMMMM    //
//    MMMMMMMWXXWMMWNKXWK0XX0Kkcldolc:;;,,,,;;;,;,;::;;;;;;;'';;;;;;;,,;;,,,,,;,,;,;:::::;,'',,,',,;oxxkkkkkkkkkkkkxxkkkkxdo:,,''',;;,'',;::;::;;;:ccc:::;,;;,,::;;;::::::::;:;;:xXXNNkoOXXKXXXXXKKNXNMMMMMMMM    //
//    MMMMMMMNXWMMMNKXWX0KKOxxoc::;;;;;;;,,,,,,,,,;;,,,;;;;;,',,,,,,,,,,,'',;,::;,,;:::;;;,'',,'';,,cl:coxkkkkkkkxdooollccc;,,,'',;,;,'',,;;:c::;,;:ccc:::;,,,,,,;;;;;::;,,,,;:clxKNNN0x0NNXKXNK0XNNNXNMMMMMMM    //
//    MMMMMMWXNWWWWXKNX00Oocc:c:;,;;;,,;;::;;;;;,,,'';:::::::,,,,,,,,,,,,,,,,,,,,,;::;;;,,,,'''',,;,:l;,,;:cdkkkxo:,,,,,,:c:;;'..;;;,''',;,,;;:::;,,,;;;;;,,,''',,,,,,,,'';cokKKxoONNNNNNNNNKKNX0KNNWXXMMMMMMM    //
//    MMMMMMWXNMWWWK0KOdoccccc;;;;,,;;::::;;;;;;;;c;';ccccccclc:;;,,,,,;;;;;;;;;;;::::;;,,;;,'''',;,:l:;:,'';oxxxl;,,,,,;cc:;,....',;'.',;;,,,,,,;;;,,,,''','.',,,,,,'',ldod0NNNXXNNNNNXkdOXXKXNK0XNWNXWMMMMMM    //
//    MMMMMMNXWWWWXkolcccccc:;,,,,;:c::;;:::;;;:;:lccloollloooolllc;;;;;,,;;;;;;;;;;;;;,';:,''''',;;:dc;:;,,;cloo:,,,,,;:cc;,'',.',''''',,,,,,,'''',,''',;;;,,,,,;;'':dOK0kxxkkkkxdk0XNXOx0XNKKNK0XNWWXNWWNXKN    //
//    MMMMMMWXWMW0oc:cccccc;,,,;:::;;:::ccc;,:c:ldoooolllodddollllll:;,,,,,;,,,;;;;;;;;',:;,,,,,,,;;ld:;:,,,,,;ll,',,,,::cc;.';;'.,,..',,,''''''''''''',;;;,,,;;,''';lolcc:;;;;;;;;::cooddddxddxxdxkkkxxxdookX    //
//    MMMMMMWXNKxc:::cccc:,,,;::;;;:c::ll:;,;cldkdlccllloddddolcllllc;,,''''''',,,,,,,,;:ldo:;;;;;;cxl;:;,',,,':l;',,;;;:cl;,;;,,''.'''',;,,''''''''''''',,;;,,,,,;;,,;;:::::::;;;:::;;;;;;;;;:;;:::::::;cdKNW    //
//    MMMMMMWKdlclc::::::;;:c:;;;:c::cl:;;;;;lOkoccllllodooodolccclll:,'''''''.....'..;clx0Kkoc:;;lxo:;;;,'',',:c:,,,,,;::lc;;;;;:;,,,,,:c:;,,'',;;:;,',,;::::;,;::;;:;;;,,,'',,,;:;;;;,,,;;,;;;;;::::::;:cllo    //
//    MMMMMNOocc:cc:;;cl:::::;;:c::clc;;:;;;:xd:;:llllooooooooolcccllc;''''''''''''..,:codxkOOkdlddl;::;,''''',:lc:,,,,;::col:;;:lc::;,cxxo:,,,',col:,,,;;;;:c::lllcllcc::;;;;,,;:oxkkkkkxxdolc::;;;;;::::::cc    //
//    MMMNOl::codlc:;od:;::;,:cc::cl:;::;;;;lo:;,;cllloooooooolcc::cll:',,''''''''..,:;;:ldxxkkO0ko:::::;,,,'',ll:;;;,,;:cclodooxkoc:,,col:;;;,'........'';ldxkkkOOOOOkxdlc:;;;;;::lx0XNNWXkOK0OOxkOOkO0000KKN    //
//    MMNxldk0NWKo:cxd:;:;,,:c:::lc;;::;,;,,:;,,,;clclooooooocc::;;cll:,,,'''''''..',,,,;:coddxkO00xc::::;;,,',lc,,;;;;:ccldkOOOOdcc:',cc;;;;,'.........';okOOOOOOOOOOOOOOkdoc;,;:::::lOXN0kOK0OOOKNXXWMMMMMMM    //
//    MMWNWMMMMMKc:kx:;:;,;:::;:c:;:::;,;;,,;,,,,,:ccloooooolcc::;;:cl:'',''''''.',''',,;;;:loxxxk0Kklccc:::;,;l:,;;::::cdOK0Oxxxlcc,',,;;;;,...........;oOOOOOOOOOOOOOOOOOOOko:;;;::::cdO0KK00KKXXKXWMMMMMMMM    //
//    MMMMMMMMMMKldk:;:;,;:::;::;;::;,,;,',;,,,,,,:lccloooolcc:::;,:cc:'''''''..','',,,;;;;;:coxxxxk0Odlccccc;:l:;:ccccdOKKOxxxkdc:;''';::;'...........;okOOOOOOOOOOOOOOOOOOOOOx:,;;;;:::cx00KXXXXXXWMMMMMMMMM    //
//    MMMMMMMMMMNK0l;;;,;:::;::,;::;,;;,',,,,,,,,,:ccllllllccc:::;,;:cc,.'''''.''..',;cc:::;;;codxxdk0KOdlccc;:c::ccldOKKkdooool:;:,'',;;,..........'',okkOOOOOOOOOOOOOOOOOOOOOOd;,;;;;;::::cokKNXXWMMMMMMMMMM    //
//    MMMMMMMMMMMNx::;,,::;;;:,;::,,;:;,::;,,,,;,,cllolccccccc:::;,;:cl;''',,'....''';lccc:;;;;:lodxxxk00kxdlccccloxOKKkdlccc::;,;;''',;;'.........'''lxkOOOkOOOOOkOOOOOOOOOOOOOk:',,;;;;::;;::o0NWMMMMMMMMMMM    //
//    MMMMMMMMMMM0c::;,;::;;;,;:;,,::,;lllc:;,,,,,clllcc::ccc::::;,;:cc;''',,'....''',:looc;:;;;;cloxxxxkO0OOOkkOOO0Oxdlcc::;,,',;,',;:ll,........''':xkOOOOkkOOOOkkkOOOOOOOOOOOkl,,,,;;;;::::lONMMMMMMMMMMMMM    //
//    MMMMMMMMMMWx:::,,;:;;:;,;;,,::,;looool;,;,,,:lcccc:::::::::;,,:c:,,',,'......''';clooc;;;;;;::loxxxxkxxxxxxxxxdolc::;,'',,,,',colc:'........'.;okOOOOOOOOOOOOkkOOOOOOOOOOOOl,,,,,;;;::::xNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMXl;:;,,;;,:;,;,',::,;looooooc;;;,,;ccccc::::;::cc:,,::;,,','.......'''',cloo:;;;;;;;;:clooddddddooooolc:;,,,,;:;,,';lc;,...''......'cxOOOOOOOOOOOOOkkkOOOOOOOOOOOo,,,',;;;::::cOWMMMMMMMMMMMMM    //
//    MMMMMMMMMM0c::;,,;;::,;,',::;,:loooooolc;;;,;:ccc::::::ccclc,,;:,,,''.........'''',:loo:;;;;,,,,,;;:::cccc::::;,,,,;::::c:,',;                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GTOWN is ERC1155Creator {
    constructor() ERC1155Creator("Ghost Town", "GTOWN") {}
}