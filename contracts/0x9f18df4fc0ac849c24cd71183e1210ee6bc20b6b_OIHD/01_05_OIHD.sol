// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 100 NFTs  100 Days
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                            .........',;;:clodkO0XNNXK0kdoc:;'...,:cl:,''.':cldkKXNNXKOkxolc:;,,''.......                       //
//                         ..........',;:clodkO0KKK0Okxdocccc:;,',;::clc:;,,,;clclodkO00KKKOkdoc:;;,''........                    //
//                      .........'',,;:loxk0KKK0Okdollc:;,',::;;;;;:cclcc::::::;,,;:cloodkO0KK0Oxolc;;,'........                  //
//                   ..........'',;:codk0KXX0xolllll:,,,,,,:cc,;c:;:cccc::::;:cc;,,,;;:ccccoxkKXXKOxdl:;,''.......                //
//                 ..........',,;cldxOKKXK0xlc:::;;::,,,;:c:;;,:c:;:cclcc:::;,;:::;,,,::;;::ccok0KKXKOxoc;,''.......              //
//               ..........',;:cldk0KKOxoooc:;,;;,,:c::cc:;;;cc:cloolcllllcllc;,,:c::;c;,;;;;::lllox0KX0koc;,''......             //
//             ..........',;:codOKXKkoc;'':c::;,;:c::;;;;;;:::;;cccccclccl:;;:::;;;c:::cc;;;;:c:,,;:coOXX0koc;,'.......           //
//           ..........',,;cldkKXKko:,,,,;:::;;:c:,,,,''';;;,,;;,,,;:clc:;,,,,,;;,'';;'';::;,;:c:;,,,,:d0XX0xl:;,'.......         //
//         ...........',;:ldk0KKOdlc;,,;::;;,,,;,'..,,'',;,,,',;:ccllclccc,,;'',,,''','..',;,'',:::;;,;cox0KKOdc;,'.......        //
//       ...........',,:cox0K0xl:clllc:;;,''',,;,..,:;;;;:;,,,;;,;;;cloc;;;;;,',;;;;,;;'..';,'...';:::lllcldOK0xl:,''......       //
//      ...........',;:ldkKKxl:,',::c:;;,'',,;:;''';c;,',;;;,'',;,.'clo:',;,'.,,,;'';,:;''';:;,,'',:;:lc:,',cd0Kko:;,'.......     //
//     ...........',;:ldOXKd;,,,;::;,,;;,;,,;;:;''';:,'..;:;'';;,'.'cloc',,;,.,,:;..',:,.'';:,;;,,',,,;;::;,';o0KOo:;,'.......    //
//    ...........',;:ldOXXd:;;;;;;'..,:;,..','';;,;;:;,'':c:,','.,,;cllc;,.',.,cl:'.';;,,',;,.','.'',;,.',::;;:dKXkoc;,'......    //
//    ..........',;:ldOXNOocc;;;,'.',;c;''';,'',c;,'';,',;;;,',,,;:clllc:;,,,',;;;,,,;'.';:,.',;,'',::,''',:::co0XKkoc;,'.....    //
//    .........',;:ldkKNXkolc:::,'',,,,,,'.',,',;,'..,;,',,'',;::,.;cloc,,;:;,''''',;;..',,'',,,..,,,;''',::ccclxXNKkoc;,'....    //
//    ........',;:ldk0NXkolcc::cc:;;,,,'...';;,,,';;'';;','.',::,',;clol,';c:,''''';;'.,:,,,',;'...'',,,;cc:::::lxKN0xo:;,'...    //
//    .......',,:cox0XNOl:;,'''',:cc::,'''',::'.',;;'',''',,,;,,;;,:lloo:;,',;,,,,'''.';:,,,,;;'....';:clc,'...';ckXX0xl:;,'..    //
//    ......'',;coxOKNKd:'..'....';lo;'....'.','','''''..,:;,'',::;colloc:;,,,;c;'..''''..',,..'.....,loc;'.'....,lONXOdc:,'..    //
//    ......',;:ldk0XNOl;''..'''.';c:''''',...';,....;:,''.,,,:ccllcoxdlclcc:;;,.'.':;'...,'...','''',;cc;'......'ckXN0koc;,'.    //
//    .....',;:loxOKNXOdc,..''.'';l:'....';,',:;,,'',,,..''',cdxxdloONXxoxxxd:,,,'.','''','',,',;'...'',::,''...',lOKNXOdl:;'.    //
//    ....'',;coxk0XWK0Ol:;;,,,;;::'.''......,,'.'','...,:cclllccc:oKWW0occlool:;;,'.',,'....'.....','.';::;;;,,;ckK0XN0koc;,'    //
//    ....',,:coxOKNW00Kxoc:;::::;''..',;,'.......,;,,,';coxo::::llkNWWXklccclddc;,',,;;........,;,'..',',::;::clokX0KNKkdl:,'    //
//    ....',;:ldk0KNNOKKd:;cc:;,...'',,,:c:,',,,;;,,'';:c,:l:clllx0XWWWNKxlllccc,;cc;,,;,,',;;,;::;,,''...,;;:c::lkX00NKOxl:;,    //
//    ....',;codk0XWNOKXd;coo:;:' .....'.';:::::looolloxxl:::lood0XXNWWNX0xoddl:;cdxolllll:;;;:;,'........';;cooloOX00NXOxoc;,    //
//    ...'',;coxO0XWNOKWkodlclc,. ....'''.';,':odcllloxkdc;cddoxO00KNWNX000kddxl::loolcc:col,';,.',,'.....':::codxXW00NX0koc:,    //
//    ...'',:coxO0XWNO0Wkdxl;;;;,..',,;cc::cloxko:::cx0ko:lddoxOOkOKNNNXOkkOOxdocldOkocc;:oxdolccll:;,,,..,;;;cooxXWO0NX0kdl:,    //
//    ...'',:coxO0XWW00W00NKkkkxoccclolllodxkkddl::ccok0dldxxOkkkkk0NNNXOxxkOOOkxdxkdlcc;:coxxxkdoc:clllcloxkkO0OOWNk0WX0kol:,    //
//    ...'',:coxk0XNWK0WKONWK00kxkkkkxl,,:cloxdc;;;:cok0O0KK0OkkxkkKNNNXOxxkO00KXXK0Odc;,::cddoc:;,,coxkkxdk00XXOKMXkKWKOxoc:,    //
//    ...'',;cldk0XNWXOXNO0WMWXo,:ccxkc;,,,;:clcodooxKWMMWWNNK0OkkOKNNWXOkO0KXNWWWWNX0oclooc::,,',,;lol::,:0WMW0ONWOkNNKOxoc;,    //
//    ....',;:ldkOKNWWO0WNOKWMWo...,::c:,';:::::;;;;,;;cloxO0KXK0OOKNNWX00KKKOxol:;;,,;;::ccccc:;,':l:,''.oNMW0OXMXx0WNKOdoc;,    //
//    ....',;:coxOKXWWXOKMN00NMk'.,:cllloxO0000OOkxdl;'......;ldk00KNNNN0ko:'.. ...,:ldxkOO000K00kooolc;''xNKkONMNkkNWX0kdl:;'    //
//    ....'',:coxO0XNWMK0KOdccoo;.;oddlldxxxddxxkkkkxdo:,......;ok0KNNNXOo;......;lodxxxxxxdddddxxdclddl;,cc,;cd0OONWNKOxoc;,'    //
//    ....'',;cldk0XNWMNx,.     .,lxkl;;::::ccc::;;;;:clol:'...,cxOKNNNXkl,...'cool:;,,',,;:::;;;;;,,oxl:'.     .lXMWNKOxoc;,'    //
//    .....',;:ldk0KNWWO'       .,lkk:..........       .';odc,.':dkKNNNXxc'.,ldl,'.      .'. ........:xdc'       .kWWX0kdl:;,.    //
//    .....',;:loxOKNWWx.    ... .lOx::,...  .ck;...',;xk;'lxxc,;dkKWNNKx:,cxxl,cOo'.',;:xKc.  ...,:;:kx;....    .dWWX0kdl:,'.    //
//    .....'',:coxOKXWW0:.  .... .c0koxoc:;'..'clcoxkxdxdllookOo:okKWNNKdcokxllooooc:oddoc,. ..,cclxolkx' ....   ,OWNXOxoc;,'.    //
//    ......',;:ldk0XNWNx'.',,,,..;Odcdkkxxxl;'...,;;,'',cdxxxOOoox0WNN0doOkoddxoc:,',,'....,:lxOxdxocxd......'..lNWNKOxoc;,'.    //
//    ......',;:loxOKXWWNl''.';:,.'kd:kNNO0X0xoc;;::,,cx0K0O0Ok0kdx0WNN0xkOdk0OO000xc;:c;;:ldxOKKOKKo:do..,::;;';0MWX0kdl:;,'.    //
//    .......',;cldk0KNWMNd.    ..'xxokOkxOXK0kxdddl;:dKWN0k0KOOOxx0WNN0xkkx0XOkKNXkl:cloodxkO0X0dxkxldc.....  ;OWWNKOxoc;,'..    //
//    .......',;:coxO0XNWMXc.     .lxc;,,:kXX0OkkkdlccokKK0OOK0kkxx0WNN0kkkk0Ok00OkdlllodxkkkOKKd;'',;oc..    'OWWNX0kdl:;,'..    //
//    .......'',;cldkOKXWWMXc  ....,olcc::oOXXKKOkoc:;:loxOK0OkxxxkKWNN0kxxxkOK0Odc:c::codkO0K0xc;::::c,...  'kWWWX0Oxoc:,'...    //
//    ........'',:codk0KNWWMXc.,:,..c;,cccldkO0Oxdc;cdkkocoONX0xdkkKWNN0kxdkKNXOocdkkoc;:lodxxxolcc;,;:'':,.'kWMWNKOxol:;,'...    //
//    .........',;:loxO0XNWMMKl:l;..ll,,;:coxxxxxx::oodxddldKNN0kkkKNNNKkxkKNX0xcldxxdd::odddxdoc;'',cc',l::OWMWNX0kdlc;,''...    //
//    .........'',;:ldkOKXWWMXocoo:cKk;,,,,;codddlccllodollxKNKOkkOKNNNKkkkOKX0xlcloolc:codolc;,..'';kk::ocoXMWWXKOxol:;,'....    //
//    ..........',,:codk0KNWWOd0XXxlk0c',;,'.'',;:clcll:cox0X0kxddx0NNXOddxxx0KOxoc::clool:,'...''..oXxckXkdKMWNK0kdlc;,''....    //
//    ...........',;:loxO0XNWkxNMNxdxOk,..,;,...';:llolok0XNXkc;'..,oxl'..,:dKNXK0kdlclll:'...,,...:0Kdo0NxxNWNX0kxoc:,,'.....    //
//    ...........'',;cldkOKXWOxXMKxKKx0o.  .,;,',;,,,;lkKXXXKx;.           'd0XXXK0ko:,'',,,,,.  .'kXOkdOOoKMWNKOxol:;,''.....    //
//    ............'',:codk0KNXxOXkOWWOk0c.   .,x0l,,;:ldxOOOkdl:;'.......';:oxOOOkdolc;,.;dk;    .oXOO0dxdkWWNX0kdlc;,''......    //
//    .............',;:codk0KNKdx0NMMNkOO;.    ',,:ccclcclllcclddddooxdodddddolcccccccc:;'''.   .cKXk00ccdXWNX0kxoc:,,'.......    //
//    ..............',;:codk0KXOxXMMMNx0Wk;.     .:ccccc::;;,''',:coOK0xolccc:;,;::::::cc,.   .':OWKkKkllOWWX0Oxol:;,'........    //
//    ...............',;:cldkOKX0kkOOkONMWk:'.    'ccccc:'.''.......:lc,.........;cccccc;.  ..,,dNMKdxkxkXWX0Oxol:;,'........     //
//     ...............'',;:codk0KK00KNWMMMNx,....  .:lcc:;,'...................',:ccccc,...''..lNMMNdokkKNK0kdoc:;,'.........     //
//     .................',;;clodkOKXNNWMMMMNx'...''.,cllc;,'',;;;;;:lool:;;;,'''':ccll:'''.. .oXMMMWXO0XX0kxolc;,,'.........      //
//     ..................'',;::cldxkO0KXNWWMW0c. ...',:lol,.....';:cloolc,..   .:oolc;'..  .,xNMMWWNXK0Okdolc:;,''.........       //
//       ..................'',,;:cclodxkOKXNWWNOc.....':dxd:.     ..':;..     'cddoc,.....;dXWWWNX0Okxdolc:;;,''...........       //
//       .....................'',,;::clodxOKNWMMNOc;::cldkOOxc,..   ,ko. ..';okOOkkdl:;;;dXWMWWXKOxdlcc:;;,,''............        //
//       .......................''',,;:cldk0XNWMMNl..,:oxO00KKOkdoolxKOdoxkO0K000Oxo:,'.'kMMMWNKOxoc:;;,,''...............        //
//        .........................'',;:coxOXNWMMNc   ..';clloxk00KKKXXK0K0Okdlcc,...   .kMMMWNKOxlc;,,'..................        //
//        ..........................',,;cox0XNWMMX:        .. ..';:cx0Odc:,.....        .kMMMWNKOdl:;,'..................         //
//       ..........................'',;:ldkKXWWMWd.                 'dl.                .oNMMWNX0xoc;,'..................         //
//      .........................'',;:coxOKXWWMNx;'....             .lc.             ....'xWMMWNX0xoc:;,'.................        //
//     ......................'',,;::codk0KNWWWXd,,;;;;'.....        .lc.        .....,,',';kNMMWNXKOxoc:;,''...............       //
//    ...................'',,;;:clodxO0XNWWWKddkdc;;;:;','........  'lc.       ......':::lkkokXWWWNXKOxdlc:;,''.............      //
//    ...............'',,;;:clodxk0KXNWWXKko:..lkOkdd:,:c;,,;,.......lc. .....'..,;;,cddxdc'.;lxOKWWWNX0Oxdlc:;,,''..........     //
//    ...........'',;;:clodxk0KXXNNXXXKKOolcloc,,:oxxdlcc:;;;;:;,'...cc. .''';;,,:ccldxl;;:odolccd0XXNNNNNX0Oxolc:;,''........    //
//    .......'',,;:codkO0KKKKKXXK0OkkxkkdxxxkO0kdolccccll:cc,,,'''...cc. ';,,;;:c::cc:ccldk00OkxdxkkkkO0KKXXXKK0Okdlc;,,'.....    //
//    ....'',;;cldkO000KK0OOkkkxxdxxdxx00OO0Oxxxoodocokkd::lc,;:,...,lc..,,';;;coxoclcclllldxkOOOOkxxxkxxxxkkOO0000Okxdl:;''..    //
//    ..'',;:coxO000OOkxkkxxdxxxxkkkO0NKOkxxdlooodoc:oxxkdclc;cd:'.';ol,';;,:::ldxo:lo:;codxdddkOO00OOOkkddxxxkkxxkkOOkkdl:,''    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OIHD is ERC721Creator {
    constructor() ERC721Creator("100 NFTs  100 Days", "OIHD") {}
}