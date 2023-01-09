// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chaos In Mine
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    lloollcccc::;;;;;;;;;;;;;,'...'',,,,,,,,,;;;;;:cccccc::::cccc:::::::cccc::;    //
//    oxxkkOxocll::;;;;;,;,,,,,,'...'',,,,,,;;;;;,'',;::::::;;:cccc::::;;;:::::::    //
//    OX0kxxO0xodoc:;,,,,;;,;;,'..'''''''''',,;;:;,,;clollc:;;;;::cc::::;,,,;;::;    //
//    K0xc;:ok0kdol:,,,,,,,,,;,,''',,''......'',,;;cllllc::;;;,'';:cccc:;,,;:::;;    //
//    Kkoc:looxkdddc,,,,,,''',,,,,,;,,'''........';:c::;,,;:c:;,,;cllcc:;;;;;::;;    //
//    0koclddddddxd:,,,,,'''',,'',,;;,,'''........',;,,,'',clc:;;:clllccc:;;;:::;    //
//    xOOxxkkkxxdol:;;;,,,''',,,''',;;;,''.......'',,,'''.,:cc::;;:clllcc::::::::    //
//    cloddddxdocc:;;;;;;,,,',,,'',;;;:;,,''...'''''''''...,:::;:cccccc:::cc::;;;    //
//    ;;:c:cc:,,,,;;;;;;;;,,,,;,,,;;;;;;,''''''''.'''........',;:ccc:;;;;::::::,,    //
//    ,,,;;;;;,,,,,,,;,;:;,:c:cllclollooolc:;,''......'''.....',,,,,'''',;;;;,'''    //
//    .'',,,,,,,;;;;:clodddxddkkOkkOkxxxxdlllloc,',:clodxdl:,''''...'..',,,,,,,;,    //
//    .''',,',,,:odddkkO00kxxxxkkkkkOkxxxoooookOdokOxddxxkOOd:;::,',cllc:,,,,,col    //
//    '''''',,';xkdodOOxxdoloc:ldddoooxOOxddddkxxkdooxkkxooxkxoodl:cdxdocclddddxo    //
//    '''''';ccdOxlx00o;;,,;:::;cloooodkkdolloxkOOdodkOdlooldddxxoodxxdlc::lllc:,    //
//    ''''.;dOxoxOxxdc,'',oOOxxdddooddOOdldkkO0OxddoodOxclxdooodkkkkxxxdxxl'....     //
//    '''..c0kookKk:'',;;:dOxolldxkOkk00OO00K0kdddxxxk00d,cdoollddddxkOkxdxdldd'     //
//    ''...cOxlx0Oo::coxdc:odkOOOkxoccoxxxkO00kxOOOkdoc,..';;:lllc:c::clxxdxxxkl.    //
//    '....;kkoxOOO000xoc:clloxkkxxocccc;':oxO00Oxc;'..''',;;lk000OOx;..okodxxkxc    //
//    .....:ddoxOkkkoc::coo:::;cdxollolcc:;;:coxdc,,::cllllc:cx00KKKKk;.;dolldkd:    //
//    .....':dkOOkOkdx00KKOl,:ldxxxkOOOxc;,,;:codldO000K000OkdoxO0KKKKk:'cdl:oo,.    //
//    .......';lookKKXXKK0xcokOkO0KXKK00x:;cldxkxdOKKKXXXK0000kddk00000kdxkdcldc.    //
//    ........',:d0XXXXXKxloOOxk0KKK00KKOxk0KKXKKOxO00KXXXK0000OxkOOOkO0Oxdoooxk,    //
//    .......''.;xXXXXXKx::xOkdkOO0xcxK0000000000OolkKKK0KKK00O0Odok000KOl:llll:.    //
//    ..........:OXK0Okd,.ckkddxclo:ck000Odld0KX0kkocxKKxlxOkkxdkd;'lddxx;..         //
//    .....  ..';xkolcc,.;oxddko:lkOOkO0XKdcokxko;oo;:oOkl;locdddxl'':::c;.          //
//    ..........,cc,,c:.,odxdoo:.,x0x:,cxkdoddcoooko::::oxdddclxddxl',:,;;;;.        //
//    .......,cc,;c::oc.,oddl::;;cdkd:''oxdollc:dOx:,lo:,cx0x;;oooxo;'c::;:l'        //
//    .......:c;;:cokOl..:occc:lldOOko,'lxdcc;'.cxd;':dl''cxd;.,:ldo;'ld:;;,.        //
//    ...........:kKKOl'.:c;coc;lOX0Ox:':dl:::cloxxl',dl''lxxoll::ll,'d0kc...  .     //
//    ... .   ...;xKKxc''cc;:x0Ok00kkx:':c::cc::d00d;,ol',oOOxl:cc::''dKO;.    ..    //
//    ....    .'.,ldoc,';ll:cdxkOkxdol,,c:;,cdloOKOxc,lc':xOK0ocdc;:',d0x,.......    //
//    .....   .',,;,,,;cl:::::,,:::;,,';cc;,:dkOOxlol:c:'cxkOOOOx:cc,,co:'.......    //
//    ...     .;odlcooxOdlloo:;'',,;;;:;,';;:ccldo:c:;c:':loxkxdl:::;'',,;,...','    //
//          .'oxxdodxdoolc:coxdolc;'.'..,,;;;;'.',,,,;c:'',,;;',:c:odlccooccc;,,,    //
//       .';:lollodxkdoc::cldkOxdoc:,',:ooc:cc:;:;,,;,,::;;;,,;clccloooooxdclooc;    //
//      .;dddlc::c:::;,....';ldxxkxoolccoddoolc::;'..':;'.':loxoc:ccoxdocclllool:    //
//      .cl:;,'''''.....','....';:::coooloxkxdl:;;;,;coc;;:oxkxc;'';:cc:;;coololc    //
//      .:;',;clllolccc:cll:;,'',,'.',,;::clodocc:;,,:lddolcl:'...........'',;clc    //
//    . .,;:lc;',,;:llllllooollloooc;,,'''''',;clllc::ccll:'..';:;;;:cccc:;,'';::    //
//       .',,.    .,:;;:cloolooollloolc::c::;,...;clloo:;cc::clllllc,,,'';::;,;::    //
//        .       ..,;:c:;,.......',;cllllllccl:'..;col:,';clooll;..      ..'..''    //
//     .   ...   . ....... .         'loloddlccol:;;ccccc:;'';cll;.          .       //
//     ..  .... ......   ....  .     .:doool;..,:clolllc:cc;..;c:,.    ....          //
//        .........  ........  .     .:oooc,.   .',;;;'.';cccc:cc'. .  ......        //
//       .......... .......    ..    'lccoc'.            .';clc:,. ............      //
//                  ......          .;lccoc,.               ....   .... .........    //
//                                  .;c:col,.                      ..     .    ..    //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract CHAOS is ERC1155Creator {
    constructor() ERC1155Creator("Chaos In Mine", "CHAOS") {}
}