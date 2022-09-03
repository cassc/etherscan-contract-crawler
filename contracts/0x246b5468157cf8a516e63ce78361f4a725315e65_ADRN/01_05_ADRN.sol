// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Adorn
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    .       ....'dKXXXXKXX00KKXN0x0NNWWN0XWWKl'...........    .....'..'''..;lc;......'..:lodddxddo;.        //
//    .       ....cOKXXXKXXK0O0KXNKOKNXNNK0XW0l'...........     .....'...''';c::,....':lddxxdocoxxo;.         //
//    ...     ...;k0KKXKKXX00XKKXNX0KXNWWXKXk:...................'...'...';ll:c:..,cdO0kxddddlldo;.           //
//    ...   .....o0KXXXK0KK0KKXXKXXKXNWWWXOo'........''''.....''',,.','.':oollolldk0K0kxxxxkkd:.              //
//    .   ......'d0KKXXK0KK0KKXXXXK0XNNWNk:'......''','.....'.':;;,..,';oxxxdxO00kkOkxxxkkxl,.....            //
//    .   ......'l0KKKXXK0K000XXXXKOOKNNk;.'''.''',,,;'....',;:::;;'.,cxkkOO0Oxxxkkxkkkxo:'....'.. ..         //
//    ..  .......;dO0OOKXX00000XXK0kxOOo,..''''',,,;;,.';;;;,;::::;,;okkkkkxl::ldkkkdl;',,.......             //
//    ..   ......''cx00OOOK0KKO0KKkdkx:'''''''';;:cc;'.',;:;'',,;::lddoccc::coxxxdc'.  '::'. ....             //
//    ..    ........;o0XKOOOOK0O00Odoc,,',;;,,;:cll:,'',;:;,'.';:ccc:;,;:lodkOx:'.     ,::,.  ...     .       //
//    ...   ..........:d0KK0OOO0kkkl;;:;;:::cloolc:;,,';:,.';::::;,,,',cdkOOdc'..  .. .,::;.                  //
//    ....  ............;x0KXK00xol::cllolodxxdol::::;;::cc:::,....,cdOK0ko;.   ..... .;::;'         ..       //
//    ....................lOKKX0o:ccldddxkOOkkxol:;:cclolc:,......ckKXXk:.. ....;xkxollddoc,.       ...       //
//    ................  ...:kKKxccoddddxO000Okxdc:loooc;,'''....:kXNKk:.  .   ..lKWWWWWWWNX0xc'.    ..        //
//    .................  ...;kOolodxxxkOKKKKK0kxoll;''''''''..,dOO0kc'...... .  .c0NNWNNWWWWNNKkl'  .         //
//    .............''...,lc;cooloxkxdxxxO000koc:;,,,,,,'.....'dOOko' .,;:::'...  .oKXNWWWWWWWWWNX0d;.  .      //
//    .................:l;..;lccdxxddxkO0ko:,...,;;;,,'.... .:dxd:.'lk0XXKKOo,....;0NXNWWWWWWWWWNNXOo'...     //
//    ...........'....,c,..,cccoddxxxddol:,'''.'''',,'..   .'lol,..l0KXXNX0K0d,...;ONWWWWWWWWWWWNX00Ox:..     //
//    .........:l:.....c:,;cc:::::::cllllccllolcc:;'..     .;::,. .:xO0xddool:'...:0WWWWWWWWWWWWNX0OOkdc..    //
//    .......;dO0k;....:c:;;;;,;:codxxxxddoodxoc:'..       .;;'.. ..;collxo;':;...oXWWWWWWWWWWNNNXK0Okxo:.    //
//    ......;x0000o,.',...;::;;::::cclooollcc:,..  ..   .  .,,......',;cool:;lc;,c0WWWWX00NWWNNXXKK0Okxdl,    //
//    ...',:oOOO00Ol,'.....,;;;;;;,,,,,,'......         .  .''........,,;::llc;;dKNWNWWKkkXWNNNXKK0Okxxdl:    //
//    .,ldxOkxkO000k;..............''''...            .    .,'.....  ....;::,,lONNNWNNWNXXWNNNXK0OOkkxdol:    //
//    ;dkkxxkxxk0Okx;..:looc'.        ..       ..    .     .'........',;:,..'dXNNNNNNNXXXNNNNXX0Okkkxxdol:    //
//    'okxxxxxxxkOOxclOXXXXKOd:. .  .........  ..  ..      .''. .....,'... .oXXXNNNNNNKO0KXXKKK0Okkkooolc;    //
//    ..:oxkkkOkkkkodk0KX0kkxl:..........    ...  ..      .','.      ......cKXXXXXNNNNNK00000kOOkxdooool:,    //
//    ....,:ldxkxxdc:looldkko:'....  ..      .'...        .;;'.      .....:x0KXXXXXNNNNXKXXOkxOKOxddolc:;,    //
//    .....',',clll:,,::;cc::lc'............'....         .;,..     ..,l:,o000KXXXXXXNN00KOoxxxKK0Oxolc:;'    //
//    ......,,':lc:;,.,oxddxddl;,.....,;,'......  ....    ';...    .,,'ll;oO00KKKKKXKK0O0KOoc:cokXKxdoc:,'    //
//    ..   .;llod:;;'':ccdOkl;;;'......... ..........   .';'....  . .;..''lkOO00000OxxO00Oxol:;:lxlcdOxc,'    //
//    ......:lccloc,''',;lllc',,....''..   .......    .,;;'..'''... ......cxkkxdoxkxookkdoooc;,,coc:ccc;''    //
//    ;;,'',,,';::;',....',...........     ......  ..,;,'....,;:c;.....'..,okxddddo:,;:c::clolodxo'..,;,,'    //
//    ;;;,,;;,,,,'';c:,'.,;''........ ..'..',;;;;;;::,'''....;ccclc:;,;;...:dxdxkkxl::cokOkddxdllc,',,,,''    //
//    ;;;,,,,,,,,',,;;:lc::cll;''.... .,,,:;;:ccc;'....... ..codddddoc,,'..'clc::okxxxO00xddxxo:;;;,,,,''.    //
//    ,,,,,,,,,'',,'''',,,;,.........  .........     .....  .:xO0kxxko,.'...'::;;ckOxkOOko:;::;,,,,,,''''.    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ADRN is ERC721Creator {
    constructor() ERC721Creator("Adorn", "ADRN") {}
}