// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paramnesia
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0olooooooooooooooooo    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0olooooooooooooooooo    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0ooooooooooooooooooo    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0olooooooooooooooooo    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0olooooooooooooooooo    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0ollllooollloollooll    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXOkOOOOOOOOOOOOOO000    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0dlo0WWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXOxxOKKKXNNNNNNNNWk::lO0O0KNWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0d;.,lxkxk0KXNNNNXXNXKKNNXXKXNWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWNWWWWWWWWWWWWWWWWWNo...:oko:lld0XNNXKKNNNK0XNNNWWWNXKKNWWWWW    //
//    WWWWWWWNNXNWWWWWXxooooooooooooooooooooo,...;ccc::,',,,;;,;::;,,,;;;l0NXKOOOOKNWW    //
//    WWWWWWWWNNNWWWWWKc,;;;;;;;;;;;;;;;;;;,'....;,.:c'...  .....     ....xX0Oxkkdd0WW    //
//    WWWWWWWWWWWWWWWWKc;;;;;;;;;;;;;;;;;,......;c;..cc.  .. ..  ...   ...xNNKkdxOOKNW    //
//    WWWNXKXXXXNNXK00x;.''.....'....'.........,ll;'....   .   ..   .    .xWNNOddkXWWW    //
//    WWWNXNNNNNNNNXK0d'.... ..........;;,',;;;:c,',,'',,,,..            .xWWWKxdoxOK0    //
//    WWWNNNNNNNNNNNXKx'...          .;ddl:;;;::c:,;;,:dkkkl'. .        ..dWWWWXOdoood    //
//    WWWNXXNNNNNNNNNXx'..           .'ll:;clllloddlloxOOkd;.          ...oWWWWWNX0O0K    //
//    WWWNXXNNXXNNNNXNO'..         . .'c:;::codoodkkkkkxooc.       ..    .oWWWWWWWWWWW    //
//    WWWNXNNWNXNWWNNNk' .           .lo;;:dkkkxolx00kxlcdl.    .. ..    .oWWWWWWWWWWW    //
//    WWWNNNNWWWNNNNNNk'             .od;;cdOOkxolldkOklcxc. .   .       .oWWWWWWWWWWW    //
//    WWWNXXNNNNXXXXNNk'             .dx:,;;::;;;;:ccc;'lk;  ..          .c0KKKKXXK00O    //
//    WWWNK0KKK00000KXk'             'dd,.';;;:clooc:,'.:o'  ..           ':clodddocc:    //
//    K0K0xoooooooood0O'             'xx;.';;cldkxl:,. ..:;.  .          .,cccccccllll    //
//    00OkdoollloxkodKk'         ..;ood0x:;;;ccllc,..   .,:.          .   .      .....    //
//    :lclkkxddxk0KOOXO' ..  .'cdOK00d:lOx;;:;;;,'..     .,. ........ ..  ..    .':ccl    //
//    XXXNWWNXNWWWWWWW0' ..;oOKXNX0kdc,..ll;;:::;,,,,.   ..,:odddxdc:;;;;;;:;;;:ccllll    //
//    WNNNWWWWWWWNNNXKd;cdxkOkxdoc:;;,'..'c:'',,',;,'......;dkkOOOkkxdolllllccllllllll    //
//    XKKXXXXXOddddkdc',ll;,,,;looddxO0Oc;okc....',,'.'...,cdxdxxxkOOOkxxddoclllllllll    //
//    K0koccc;,',;::,......,;cxKXXXNNXKkd;.;;........,:,;,,oOOOOOOOOOOOOOOOxdddoodddxx    //
//    Kkl::ccllooddl:,,,,;:::cc:::::cc;,.............',;,;cxOOOOOOOOOOOOOOOOOOOkkOOOOO    //
//    KK0KKKKKKKKK0xlodl::;,.'',;;;;:lllllc;,,;;:;:cclolclk000000OO00O000OOOOOOkkOOOOO    //
//    KKKKKKKK00000OkkocloolcccloddddoloocclodxxkO000OxolokOOOO00OO000000O0OOOOOOOOOOO    //
//    KKK000000OkkO00xc:coddxxdxkOO00OkkxddocodkO00OxkkkkkkO000O000000000O00OOOOOOOOOO    //
//    KKK0kkOOkxkO000kl:::cldxxxkxddddoddxkxoddkOOOkk00OOxoox000000000000000000OOOOOOO    //
//    K0K0dlloxOO0000xc;;;;;;;;::;;;;;;:cccoO0000000000OOOx:lO0000000O00000000OOOOOOOO    //
//    0000kl;lO000000Oo:;;;;;;;;;;;;;;;;;cxO0000000000OkO0kldO0OOOOOOOOO0OOOOOOOOOOOOO    //
//    000Oo'.o00000000Odc:;;;;;;;;:cclodxO000000000000kkO0OOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000k; .oO00000000Okdl:;;;;:dkO0000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000o. .,d00000000000kl;;;;cdOOO0000000000000OOkxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract PARAM is ERC721Creator {
    constructor() ERC721Creator("Paramnesia", "PARAM") {}
}