// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mini graphic world
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                               .;cc;,:c:',::,'',;:;;;;:;;,,     //
//                                                                                               .col::cll:;ccc:;;clccc:clcclc    //
//                                                                                             .:ooc::looc:lc:c::ccc:::cllolcc    //
//                                                                                           .:odo::llddc;cl::c::cll::clloolcc    //
//                                                                                         .'cddoccclddl:ll:;::;:cl:clllolccll    //
//                                                           ..'''....                  .',;lddocclldolcllc;;;,,:cc:clolccoddo    //
//                                                     ... ..,;:clooool:;,,''..'''.'',;::::odolllloolc:clcc;',',:cc:col:cdddoo    //
//                                                  ..'..........',;:clooddooddoooloollcclooolccloooc;clclc,,;'':lccll:coodoll    //
//                                                .''',,,;;,,;,'....';;:::;;::ccccccloolloollccloloc';lcll:,;;''coccoc:coollll    //
//                                             ..';:;.':loooooolc::;,,,:clll:,,;:clllllloollcllool;,:lcloc:;;;,;locclc:oolcodd    //
//                                            .'.;cc:,;;;:ldxxxdooooolc;;:coddllc::cllcllcccccc:;,colcllccl;;c::lo:cl:lolloddx    //
//                                         ..,;'.:::l::lc;;clloxxxddoooolc;;:ldxdolllc:::;;::;,,:cc;:olcco:':c;;locl::olloxdoo    //
//                                        .;:;:,.;ccc:;colllccc:clooddlloolc::::clllllllcc:;;,;:c;',clcll:',c:;;clcl:cllodollo    //
//                                       .;:;lc,,::cl:,,:clolcc:,;::ccloollllll:::::cc:;;;;;:c::;,,:clooc:;:l:;:lcllcllooc:odd    //
//                                      .;::,:l:cc;;cc;;::;;;;;;;,',:::cccolcc:::::::;,,;;::;,,,;;cloolccl::oc::l:llclol:clool    //
//                                      'c:,..;:;::'';:;;cc:;,,'....'';c:;:cll:;,',:cc:,,'',,,;:clllc:;:l:;ll:::ccccclc;clcccl    //
//                                      .;,....;,';;;'...,::;,,,,:ccc;'':loccllc:'.'',:lllc::cccccllc:::,,coccc:;::;cl:::;:lod    //
//                 ......                 ....;loc,',,,:coxO0OOkkOOdldc'':odoooolc:''...',:cclccccc::cc,,cc;c:,,,,,;cc:,,colll    //
//             .:ldxkOOOxl;.              .'..'dXO:.,llclxKXXXXXK0kocl;;;,coodoloollc::;'',,'',;::cccc;',;;::;;;..;cc;,:lolclo    //
//            ,xOkxk0xdxOOkd:.           .'',c:c0XkccodOKKKKKKXXK0Od;,,;:;,coooolllolccl:;;:;;:::cc:;,,;:cc:,;c'.,;;;;clccllll    //
//           ;xxOKKKK0kkOOOkx:         .,::lxo:oKK0K0O0KXXXXXKXX0xlc,;:;,;,;ldlllc:clcccllcc:ccccclcc::cccc;;c;',,,;cccc:;;;;;    //
//          .oOOKKXKKOk0K0kkkx'      .:looooo:'d0xdOKXXXXXXXXXXKOdlolccc:;,''ldollc::lllcccccccccccclcccccc::,',,;:::,''.',;:c    //
//          .dOkKNNKKOxdk0kdxkl'..;,,lllccllol,,:loxKXXXXXXXXXX0koclxkolllc;.'lddlcc::cloolc;:cclllllc;;;;;,''',,,'....',;;;;:    //
//          .oOkxkKXKXXkO0xkdloc:oxlldl::,,lol:,;llldxk0XXXXXX0xllld0X0dloolc;,:ldolllc:clcclc:;:ccc::;;,'''........,,;;:loooo    //
//       .....:xxk0Ok00xkkkd' .;dko::lccc;:ol:cc'.',cdO0XXXKOdlloxxOXXXXx:colc:;;;codollll::::;;,,;;::;,.....'',,,;:cc::::cccc    //
//       ;dc;. .cxxkOkddlc'.   'lllccc:cl::lc:l; .,lkKXK0kdl;;ldxOKXXXXXXd,;llccc,',:cloollc:;:::;;;:::;;;:::::;;;;:cclooooocc    //
//       .lddo:..'lxl'..  ;l.  .:cccll:ld:,::cl,. ,::oolc:clc;;d0KXXXXKKXXx;,:ccccc:;;;:::::,,,,,;;:cloooooooolccc;,,,;:lollcl    //
//        .lxoodl,.lko'   ok. .;docloocoxl,;ccc,'..:c:cllc:ccc;oKXXXXXKOKXXOc;:cclolc;;,,,,,,;::cloooddoooooooodddol::;cllllcc    //
//         'kkodkkdoxOOo,'lO; .cdo:cxoclodl;,,;,':;.,ccllcc::c;cOK0KXXKO0XXXXkl:clollcc:;;::cclllllllllllc::;;:cllllllc:clcclo    //
//          ,kOxxxdxxkOOxdkKx..cclccllolccll:;'',;ol::cc:cclc:,cO0k0XX0xkKKXXK0xolc:::cc:::::cllllollllcccccc:::;:cc:ccc;;:ccl    //
//           .ck000Okkkdolx0K:.,ccc:cccolc:;col::,,:oddc;,,,:loxOkkOXXOxxOkOOOkOOOxolllc:;''';::c::::cloollloodolcccc::ccc::ll    //
//             .cx0KKXX0OxldKd.,l:,:ll:;:ccc::::c:,',:lodxxooxkkdddxO0OdoxkkxkkOKKKKKXXKOkxxdlol,.,;:clllclllloooxdlllccllc::l    //
//               .':oO0KXXkkK0:,c'.,,;;;,',;,..':loodxOOKXX0OOO0kxOkdlodxOK0000KKXXXXXXXXK0kOOOO:   .:c:::;;;;cllodololcllc:;l    //
//                   .cdk0XK00x,.       .     .;d0K00KKKXXXXK0OOkdol;..'oOOO0KKXXXXXXXXXKkxkddk0d.   .;;;;;;;;,;:loooolcccc:;:    //
//                   .cccxKXXKO:             .'ldxKXXXXXXXXXXKkdc,'.    .o0KXXXXXXXXXX0OkodOxokXx.     ':cc:,,::;;cloooc:::c;:    //
//                   :l,.,kXXX0x'            .,dkoOXXXXXXKkoc;..         .oKXXXXXXXXXX0Ox;o0OlcOd.      'cclc,;c;;;:olll:;::;;    //
//                   ,o:',cOXXKOo.          .':dccOXXXXXXk:.              ,0XXXXXXXXX0Okl;oKkc;xl       .:lloc;cc;;;llcl;,cc::    //
//                    ,l,,coOXKOkc         .,'::;odkKXXKd,.               oXXXX0xkKXX0dcc:dKd:cOc       .:oloocll:;;::cl;:lc::    //
//                     .,:cccodloo,       .d0xlldxloKXXKc.                oXXXX0xlxXX0::cck0o,d0;       .clldd::c:;;;;lc;cc::c    //
//                       .'coc;:ccc,     .oXXXKOkxlxXXXO:.          .;:,.'dXXXXKOoo0XKd::lkOl,xk.       .clldo,;l;.';c:::;;:lc    //
//                      ,,.:olc:c::l:.   cKXX0kkxodKXXXOl,.     ,lodOXXKKKXXXXX0Ool0XXKd,lOkodKd.       ;ccol;;c;..:c:cl:,;olc    //
//                      .cloooool:;';;,;;o0KOkkxld0XXXXXOc,'. .lOXXXXKKKXXXXXXKOOoo0XXXk:okdkKKc       ,lccc;;;'';:,,col:;ldlc    //
//                        :xo;,;oo:,,,,:lxxooxdlx0KXXXXX0o;'.'dOKXXXXXXXXXXXKKOkkloKXXX0lcdk00k,      .;c:,''..,:;'':cllclol::    //
//                     .;'.:dl::odxdlc':kdoo::lxOKXXXXXXKxllcoOKXXXXXXXXXXXXK0kkxlxXXXXX0k0X00x.    .'',;,',;;cc:,.,:lc;cloc':    //
//                      ';,,cxkkdooddoc:od::lcoOKXXXXXXXKklcdO0KXXXXXXXXXXXXK0kkolOKXXXXXXX0doc. ..',::::::::ccl:'.;cc::cll:;c    //
//                    .,cc;;cldkklcclkkl;::l0xl0XXXXXXXX0xlcx0KXKKXKK0KXXXXX0Okxld0KXXXX0kdl;'.. .;clolc::::clol:;;c::;;cll:,:    //
//                  .;c;:, .ldollxko:cdko:,:kddKXXXXXXX0kxook0KXOdxxOOdOXXXKOkxocd0KXXOo:,,,:c'.':lclc::;:clodl:c:ll::c:llc:;:    //
//                  ,ol::,. ,ooooldkdoccoxc:c:dKKXXKKK0Okxolx0XXOolllloOXXKOOdolcx0K0o:;,;,ckx;'coc::c;,;:ccol,clloo::olllc;,'    //
//                 ':cl..;;,lo:,:dddoooddl;ldclxOOOOOOOkoodlox0XXK00OOKXK0Okolo:lkOOc,c::clkOo''loc,,c;,::;:o:':llddoccl::ll:;    //
//                ,ooo'    .,lc;:;coll:;;ld:,ldccxOOOkdccoxddxxkO000000Okxollll:oOk:'cl::cd0k:.'ldl,,:;;:;,;lc,;::lxddlcc:;:cl    //
//                :o,'.      .cxxoll:;coccoxd:ldoxxxxocclodddxkkkkkkkOkxoccolll;ckl';ll:;cx0d;,,cdd:;c:::;,'cc,,;;,ldddlc:,',,    //
//                .oc;c.      ,k0OOko:;lxolloxOdcllll:;;cc:c:;;;::;::::;;:cccldddd:,cooc;;lk:':,:oolcc:;:::,,;;:::;;:lodoolc:,    //
//                 .;,co.      ;kKXX0xddoc:ckXx:dkxoc;,;looddddoooooolcllllllodkKKo;;cdo:,,;..:ccclollc:,;ll:;',clc:;;;,,,;;;:    //
//                   .c:','.    cKXXXK0Okxo;.,c:ldxkkocllc;;::c:loodxdddddddddddoxoc:;col:,.  .:ooc:cllc:;::cll:::;,;::;;;::cc    //
//                    .;;coc;,. .cOK0OOOxc.     .cxxkkxxxdoooddolc::::c::;;;,,;;:,;lc;::llcc:;,;:cc;:::::clc::cllc;,,'',,;;:cl    //
//                      .',;:l:;..'cooc,.        'oxdddxolcclodddollloddddollldxxkxddc;,:llodolcc:;;;:::;,;:colc::::::,,,,,:cl    //
//                         .,cllc,..              ;kOOOOkxdddxddolcc::;;:;;::::cloolokkol;..';;,,'...  .....,;:lllcc:::cllc:::    //
//                            .:l,.  .'            ckOOO0KK000OO0Okkxddddoollllllooxo,....                  .',;::llccc:coolc:    //
//                              ..  .:.            .o0K00KXXXXKXXXKK00OOO00000OxdxxOx.                        ',;:cc::lc:lddoo    //
//                                  .,'             ;O0000KXXXXXXXXXXXK0OOKKKKOkxkkOx'                        ''':clc:clolldxo    //
//                                                  'k0O0KKXXXXXXXXXXXXXX00XXXXKOkkkO:                       .,..cclocclodlodx    //
//                                                  :OOO0KXXXXXKKXXXXXXXXXXXXXXX0OOO0d.                      .;''clll::lddoodx    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract grphw is ERC721Creator {
    constructor() ERC721Creator("Mini graphic world", "grphw") {}
}