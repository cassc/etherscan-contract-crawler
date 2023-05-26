// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ANiMAtttiC EDitttiONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK0OkxddoooooxkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNX0Oxoc:;,'''.....'';cdOXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXK0kxdoc:;,,'''.''',,'...',:cokKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWWX0Okxdoc::;;::ccc:::cloolcc:::::cldOKWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOOkdolc::;;;;,,,,,,,,,,;;;:::cllclooxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWNX0Okkxdolc:;,,''.....................',;:ld0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWNK0Okxdlc;,'...................',,,,,,'......';lx0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNX0Okxdl:,'......................',;,,,,;;,'.......';oOXWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNK0Okkdoc:::cllooddddoollc::;,''....,;,'..',,'...........;oONWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWX0OOOkdlloxkO000KKKKKKKKKKKKKK0Okxdolc:;;,'.''''...  ........:kXWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWXkoxkkd::xOKKXXNNNNNNNNNNNNNNNNNNNNNNNXX0Okoc;'.'....  .....  ..;xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNO:'ckdc:oKNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXOl,....     ...    ..;kNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWXd'.'lo::xNWWWWMWWWWMMMMMMMMMMMMMMMMWWWWWWWWNNX0l.....     ..........lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0l....cc'lXMWMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWNNNXO;.. ...     ..........;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNO:. ...c;'xWWMMMMMMMMMMMMMMMMMMMMWWWWWWWNNNNNXKo.   ....       ...  ...'dNWWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNx,..   'c;,OWMMMMMMMMMMMMMMMWWWWWWWWWWWWNNNXXKx'     ...        ..   ....dXWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMXl...   .'c,,kNWWWWWWWMMMMWWWWWWWWWWWNNNNNXXKKd'        ..       ...   ...'dKWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMKc....   .,c'.oXWWWWWWWWWWWWWWWWWWNNNNNXXKKKOl.   .      .        .     ...,lOWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMK:.....   .;:..'dKNNWWWWWWWWWWNNNNNXXXKK0kl:'.   ..                     ....,;kWWWMMMMWWWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMK:.....    .;,. .;xO0XNNNNNNNNXXXXXKK0Od:.       ..                     ....'..kNWNNXKxldKNWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMXc  ....    ';.  .:,';ldkO00KK00Okxoc;'.         ..                      ....,:x00Okxo' .'l0WMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNl.  ....   .'' ..;:.   ...';lc,''..  ..                    .            ..,cdkkxxoll;.    'dXMMWMMMMMM    //
//    MMMMMMMMMMMMMMMMMWd.   ...    .'..',:,.   .  .,;....  ...       ...          ...      ....';looolc:;;c'      .:0WWMMMMMM    //
//    MMMMMMMMMMMMMMMMMWk'    ...    ...,',:.    . ..;'...  ...      ....          ............';:::;;;,'',:.       .'xNWMMMMM    //
//    MMMMMMMMMMMMMMMMMWO,.   ...     ..;'.:,     ...''.... ...     ..........    .............,,,,''''..',:.     .....oXWWMMM    //
//    MMMMMMMMMMMMMMMMMWk;... ...    ...'..''. .. ....'........   ................'',,''......'''.........',.       ....cKWWMM    //
//    MMMMMMMMMMMMMMMMMWk,.....................''''',,,''''..    ............',;:::::;'...................''.         ..'dNWMM    //
//    MMMMMMMMMMMMMMWWNX0xdddool:;,'......',;;::::;;;,,,,,'      .......',;;::ccc:;,''.....................,,,;:ccccc:cccdKWMM    //
//    MMMMMMMMMWNNNXK0OOOkkkxxddooc:;'''''',;;,,,,,''''.''.    ..''',,;:::::::;;,''''......................',:clodxxkOOOOOXWMM    //
//    MMMMMMMWXOOOOkkxxxddolllc:::;,,''''''................   .';:::::::;;;;,'''...........................''''',;cokO0KKNWMMM    //
//    MMMMMWMXdcdxoooollc:;;,,,''''........................  .,::::;;;,,,''''................................'..':xKXXNWWMMMMM    //
//    MMMMMMWk,;l:::;;;,,''................................ .';:;,,,''''........................................oXWWWMMMMMMMMM    //
//    MMMMMMWd.';,''''''......................................',,'.............................................dNMMMMMMMMMMMMM    //
//    MMMMMWNl..''.........................................'..'''.............................................oNMMMMMMMMMMMMMM    //
//    MMMMMWK:.................................................''............................................cXMMMMMMMMMMMMMMM    //
//    MMMMMNd'.................................................''.......................................... ,0WMMMMMMMMMMMMMMM    //
//    MMMMWKc'............................................',...''...........................................lXMMMMMMMMMMMMMMMM    //
//    MMMMM0:'...........................................;x0l..''.........................................':kNMMMMMMMMMMMMMMMM    //
//    MMMMMXl',..........................................cXWk'.','........................................:xKWMMMMMMMMMMMMMMMM    //
//    MMMMMWkcc,.........................................cXMK:.',,,.......................................lKNMMMMMMMMMMMMMMMMM    //
//    MMMMMMN0kl'.''.....................................;KMNo..,::,......................................xWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWNKd,''''...................................,0MWx'.,:c:'....................................,kWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNd,,,,''...........'...............'.....'kMMK:.',;c:....................................:0MMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWNxcc:;,'''........''.............''......dWMWd'''',:,..........''......................'lKMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNOdol:;,,'''.....,,.............,;......lNMW0:',,',:'.........,,....................',:xNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWKkxdlc:;;,'....,;.............;;......:KMMWx',;,.,;.........,;,..................';coOWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWN0kxdolcc;,''';:,....';'.....;:..'...'OMMMXl',;,.',.........;:;..............'',;cdkXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWX0kxddolc;,;:l:....'cc.....;:..;,...xWMWW0:.';,.''........':c;'........''',,;cldk0NMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWWX0Okxxdocclol,...':l:....;c'':;...lXWWWWOl;','.''........,cl:,'....'',,;::loxk0XWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWWXKOkkxdddddc'...,lo;...,c''c;'..;0WMMMNXk;','',,........;ldl;,''',;;:clodxk0XWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNK0Okkxkkxc'''';ol,..,c,'::',''xWWWWNNKo,'',,,;.......':odoc:;;:cclodxkk0XWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWNX0OOkOOxc,,,,:ol,.,:,':c,,,';llc:,,'.''.',;;:'....'',cdxdolcloodxxkO0XWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWNK00OOxl:;;;cdl;;c;':l:;;;'....    .',.',;cc;'.'',;:oxkxdddxxxkkOKNWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXK0Okdlc:coxoclc,;ol:;;,,,''......',..,;coc;'';clodxkkxxkkOO0XWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0kdolodkxol::lc,,;;;;,'.......',..';col:,;loddxkkkOOOO0NWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXKOxddxkxdlcll;,,;:,;::;,..',;c:'.',;col:ldxxkkOOOO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxxkkxolloc::::'.,:ccloxkkxdc'..',cdoldxkkOOOO0KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ANMTCE is ERC1155Creator {
    constructor() ERC1155Creator("ANiMAtttiC EDitttiONS", "ANMTCE") {}
}