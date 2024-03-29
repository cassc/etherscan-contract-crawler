// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rise of X&ND
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//                                 'dOKXKkc.                                                                                 //
//                                 ,dOKXKkc.                                                                                 //
//                                 ;x0XNXOl.                                                                                 //
//                                 :k0XNXOl.                                                                                 //
//                                .cOKXXKOl.                                                                                 //
//                            ..'':x0KXNXKd,..                    ..                                                         //
//                          .:oxkO0O0KXXKK0OOxol;.              ........'''....''...                                         //
//                          ..;ldddk0KXXK0000Okxc.            .......,;col,....,;;:,....'..                                  //
//                               .,x0XNNXKx:,'..      ........,;,......':llc,..';oo:c;.......                                //
//                                'x0XNNX0l.         .'.. ..;:,...........,colcc,;odoo:.......                               //
//                                'xKXNNX0c         ......,c;....,;'.;lol:,,lkOd:,:c,'','....'.                              //
//                                ,xKXNNXO:        ...',;looc;,,;ol;,:;;dxxkkxo;,,;ol'..';:;....   .....                     //
//                                ;kKNNNKx,       ...,loxxkkkkkkxkd:,:cdO000xl::;,;lOOc.,dko'..  .,,..'.....                 //
//                                :kKXNNKo.      ..';ldxkkOOO000000d;;dKKK0kkkdc,';;lO0xdkk;. ...........,'...               //
//                                :kKNNN0:      ...;ldkkOO000000KKKOc;xXKKK0Oxl;',:;:d0Kklll' .'...'.....'..,'.              //
//                               .:OKNWNx.      ..,ldxkOOO000KKKKXXXd;oKXXXXKkc;:c::lO0Okl,c:..'.....''',,...'.              //
//                               .l0XNWKc      ...:dxkOOO000KKXXXXNXk::ONNXXKOxolc::oOxcll..:'.......,,',;,...               //
//                               .l0XNWO'     ....ldxkOOO00KKXXXXNNN0c:kXNXXKKKOoll:cll,':'.......,'.;,.';;'.                //
//                               .o0XWNo.     .'.,oxkkOOO00KKXXXXNNN0lcxKXKKKKXKxllc:'.,c;,.'...''''.,;..,,'.                //
//                               .o0XWK;     ....:xkkOOO00KKKXXXNNNNKo;l0XKKKKXKxlcc:,;c:'','...,''..;,'',....          .    //
//                               .codxc.     .   ,dkOOO00KXXXXNNNNNNNk:cOXKKXXXKdccc:''',cddc...'''.':'.';,             .    //
//                               .c,...           .:okOOOO0OkxOKXNNNNKolkkxKNXkl:cc:::xkk0XK0d,''..';,'..;:.                 //
//                               'do,....           .,::,,''..dKXXKKK0l:oc:ONXx,.;c:cd0XXXXKKo.....,,,,...;'                 //
//                               'x0Oo,..    .       ..  ..  .,clkXNX0doo,.:0XKk::lccx0KXXXKk'  ............                 //
//                               'xKNNd..            ;dc....    .oXNXXKKOdl;c0XX0xc:lkKXXXK0:.         .....                 //
//                               ,kKNWk,,.   .,.  ..'xXKo....   .:0NXXXXXKKx:oKXXKdclxKXKKk:.                                //
//                               ;kXNWO:l;   .;.  .,dKNNXkc'.    .dXNXXXNXK0dcOXNXOdoxKKkc..         ..                      //
//                               ;OXNWO:c;   .;.  .oKXNNNNXOxc....lKNNNXNNXK0kKNNN0doxOkc..          .                       //
//                               :OKNWO:c,   .;.  .dKXXXXXXKXO;...;OXNNXNNNNXKXNNNOoldOx:..                                  //
//                               c0XNW0:c,   .;.....:dO0KXXXN0:...'xXXXXXNNNXXXNNXkooxOxc,..                                 //
//                               ;dxkkl...   .;'..   :O0KXXXXO,  .;OXXXXNNXXXXKXNKxodkOd:,,'...                              //
//                               ..........  .,;'.   'd00KKK0c.  .lKNNXXNNNXXXKKXKxodOkl:;:;,,'..                            //
//                           ...............  ':,..  .d0KKK0o.  .l0NNNXXNNNXXXXKK0xdkkl::::::,'''..                          //
//                          ................. .:,... .;lk0kl. ..cKNNNNXXXXXXXXK00kdooc::::::::;,,,'...                       //
//                         ..............'.'. .,;....,,.cxc.  ,oOXNNNXXXXXXXXKK0xool::::::::::;,,'',,'...                    //
//                        ..............'''''. .,''..;' .,.  .d0XNNNXXXXXKXXK00xlodl:::::::::;,'.',;,'.......                //
//                        .............'''''''. ','.',..    .:0XXNNNXXXXKXKKK0k:.co::::::::;;,..''''.............            //
//                       .............''''''''...;''','.    .dKXNNNNXXXXXKXK0Ol..:l:::::::;;,........................        //
//                     ...............''..','''..,;;;,'.    ;OXXNNNXXXXKKXK00k, .cc;::::::;;'...........................     //
//                    ..............''...''''','.';,.',.   .c0XNNNXXXXXKXX0OOo,.,lc;::::;,,,.............'',,,,''''''....    //
//                   .............'''''''''''',,,..,,,'    .o0XNNXXXXXXXK0OOko:;cc:::;;,,,,'.........',;;;;;;,,,,,,,''''.    //
//                  .............'''''''''',,,,,,,,;,,'.   .d0XXNNXXXXXXK00kxd:,:c:;;;,'',,......',;:::::;;;;,,,,,,,,,''.    //
//                 ..............'''''''''',,,,,,,cc,,'.   .o0XXXXXXXXXKK00kool,';;;;,'.''....',:::::::;;;;,,,,,;;;,'''..    //
//                ...............''''''''''',,'..';,,;;'    ;kKXXXNNXXXXKK0klcl;,:;;,'.''...,;::::::;,,,,,,,,;;;;,,''',,'    //
//    .           ...............''''''''',,,,....'',;:c,.  .;kKXXXXXXXXXK0Oo;::;;,'..','.,:::::::;,'',;;;;;;,,,,,,,,,,''    //
//    ooo:.      ................''''.'''',,,'''''',,;:c:.   .cO0KXXXXKOOOkxd:',;,'.'''',;;;;;:;;'.'',;;;;;,,,,,;;,,,,'',    //
//    xxd:.     .................''...'''',,,,,,,,,,;;cll:.   ,lkK00XN0xkkdxOOo;'',,,,,;;;;;::;'..';;;;;,,,,,;;,,,,,,,'''    //
//    lc,.     ..................''..'''',,,,,,,,,,,;:lllc.   .,cxk0XNNX0xodOX0:.,::;;;;;;:;;,..';;::;;;;;;;;;,,,,,,''...    //
//    ..      ...................''.''''''',,,,,,,,,;clll,    ..;dkOkONXOkxxkOd;,:c:;;;;;;:;,..,;::;;;;;;;;;,,,,,''......    //
//           ... ....................''''''',,,,,,,,;lolc,.   ..':ccx0KXxoddoc;,;cc:;;;;;;;'.';;:;;;;;;;;,,,,,''''''',,''    //
//           ....  ..................''''''',,''',,,col:,'.     .',;::cl:;;;,,;:ccc:;;;;;;'.';;;,,,;;;,,,,,,,,,,,,,,,''''    //
//           ......  .................'''''',,'',,,;:;'....'.....;::::::::ccc:cccccc;;;;;'.,;;;,,,,,,,,,,,,,,,,,,,,,,''',    //
//           ........ ................''''''''''',,'.   .';,',::ccccccccccccccccc::::;;;'.,;;,,,,,,,,,,,,,,,,,,,,,,''',,,    //
//           ...  ...... ..............'''''''''',,.     .,:ccccccccccccccccccccc:::::;..,;,,,;;;,;;;;;,,,,,,,,,,,,',,,''    //
//            ...    ... ..............'''''''''',,'.    .';:c::ccc:::cccccccccc::::::;,,;,',;;;;;;;;;;,,,,,,,,'''''.....    //
//             ......    .. ............'''''''',,',.     ',;:cllc::::::::::::::::::::::;,...''',,,,,,,,,'''''''.........    //
//               ......  .. .............''''''',,,,,.    .,,;lxkkdc:::;:::::::::::::::;,....',,,;;;;;;,,,,,,,'''''''''''    //
//                 ..    .  ...............''''''''',.    .',,;:lxko:::;;;::::::::::::;,....,,,;;;;;;;;,,,,,,,,,''''''...    //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract XANDYLAND is ERC721Creator {
    constructor() ERC721Creator("Rise of X&ND", "XANDYLAND") {}
}