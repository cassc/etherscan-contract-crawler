// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JakNFT - static
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    kkkkkkkkkkkkkxkx;    .okkkkkkkkkdc'                 ,xkkkkkkxxkkkkkkkkkkkkxkkxxxxxxkkdccoooxxxxc.                     ,dxxlc:lxxxxxddddddddddddddddddo    //
//    kkkkkkkkkkkkkkkkdc' .ckkkkkkkkkkkkl.                'xkkkkkkkkkkkkkkkkkkkxxxxdxxkkkko,. .lxxxoc::'                    .lxo;..:xxdxxdddddddddddddddddoo    //
//    OOOkkkkkkkkkxxkkxxdcokkkkkkkkkkkkkd.                'xkkkkkkkkkkkkkkkkkkkkxodoodkkxko'...oxxxdcoxc.                   .oxo;';:cdxxxxxxxxddddddddddddoo    //
//    OOOOOkkkkkkkxxkxxkkkxkkkkkkkkkkkkko.                'xkkkkkkkkkkkkkkkkkkkkxxxxodkkkkkdoccdkxdxodxl.                   ;dxdc::,:dxxxxxxxxxxxddddddddddc    //
//    OOOOOOOOOOkkkkxddkOOkkOkkkkkkkkkkko.                .dOoclxkkkkkxxxkkkkkkkkkxxddxkkkxkxxdxkdodlcl:.                   cxxxd:..lxxxxxxxdddxxddxddddddd:    //
//    OOOOOOOOOOOkOOkkkkOOkkOkkkkOOkkkkkd.                ,xkxc,:dolxkkkkkkkkkkkkkkxxxkkkolxkkkkkkkxo;,,'.                 .cxxxdoc:lxxxxxxxdddxdddxdddddddd    //
//    OOOOOOOOOOOkkkkkkdcdkkkOkkkkkOOkOko'               .ckkOc .ddcdkkkkkkkkkkkkkxkkkkkkkkkkkkkkxkkxddolc.                .lxxxddo:lxxxxxxxxxxdddddoddddooo    //
//    OOOOOOOOOOOOOkkkkd:;cdkOkkOOkkOOOkk:            .'.'dOkOo,lkxdxkkkkkkkkkkkkkkkxkOkkkkkkkkkkkkkkkxxxx:.               .ododxdl;lxxxxxxxxxxdddddooddollo    //
//    OOOOOOOOOOOOOkxkdll::dOOOkOOOkOOOOOl.           .oookkkkOOkkkkkkkkkkkkkkkkkxxxxxxxkkkkkkkkkkkxxxxxkkd;               .oxdol,..,dxxxxxxxxxddddddddddood    //
//    OOOOOOOOOOOkkkxxl..':dkkkkkOOOkkkOk:.     ';..;ccdodkxdxOkkkkkxxkkkkkkxxxkkxxxdldxkkkkkkkkkkkkkxkkkkx;               'dxxdo;  .dxxxxxxxxxxxxdddddddddd    //
//    OOOOOOOOOOOl.:xd,.;lclxxkkOOOOOxooo;.    .cxlcoxOocdkOkkkkOOOkkxdkkkkkxxxkkxdl'.,;;;;;;::;;;;;;,,::;,.               'xkxdxo. ,dxxxxxxxxxxxxxxxxxxddxd    //
//    OOOOOOOOOOOo,;xo..okc';xOOOOOOkc. ..       ...,okl,,okkkOOOOOkkkkkkkkkkkkkkko.                                       ,xxxdc;.'lxxxxxxxxxxxdxxxxxxxxddd    //
//    OOOOOOOOOOOxoxOOlcxkl;oOOOOOOOOdc::;.     .;c:cdkkxlokOkkxxkkkkkkxdl::lxkxxxdoc:::::;;,'......                       'lddl;,..lxxxxxxxxxxxxddxxxxxxddd    //
//    OOOOOOOOOOOOkOOOkkkkOkkOOOOOOOOOOOOOl.  .,dOkOOkOkkkxkkkkkkkkkkOOkxolodkkkxxxkkkkxxxxkkxdkxxxxdl:co,                  .',,::. ;xxxxxxxxxxxxddxdxxxxddd    //
//    OOOOOOOOOOOkOOOOOx:ckOOOOOOOOOOOOOOOx;  'dOkkkkkkdokOOkkkOOkkkkkkkxdodxkkxxxxkxxololodxxxkkkkkkkxxx;..               .odooxl. ,dxxxxxxxxxxxdodxxdxxddd    //
//    OOOOOOOOOOOkOOOOOxcokOOOOOOOOOkOOkOOOxc:okkOOkOxkocxOkkkkkkxxkxkkkkxdxkkxdxkddc,;:'.,:coxkkkkkkkkd; ..               ,dxxxdl'.;lxxxxxxxxxxxdoodxdddddd    //
//    OOOOOOOOOOOOOOkOOkkkOOOOOOOOOOkkOkOOOkkkxdodxkxxo::dxddddddooollxxlccolc:,;:;.. ... ...'cxkkxkkxc;;...               ;xxxx:..llcxxxxxxxxxxxxdddddddddd    //
//    OOOOOOOOOOOOOOkkkxkkOOOOOOOOOOOOOOOOOOx;.....,;c:.,xxxxdxkdl:,.....   .                 .:xkkx:,..:;.               .cxkkxl,;ollxxxxxxxxxxxxxxdddddddd    //
//    OOOOOOOOOOOOOOOOkodkkkxkOOOOOOOOOOOOkd;. .    .;lcoxkkkkkkx;.   ......... .'.            .;dko':dl,.                ,dkxxkxoddlokxxxxxdxxxxxxxxxxxxxxx    //
//    OOOOOOOOOOOOOOOOOxoloddkOOOOOOOOOOOOd:..      .cdkkkOkkOkOk,  .';:;;,;;,''''..             ':;;clc'...              'oxxxkkxxklcxkxxxxdxxxxxxxxxxxxxxx    //
//    OOOOOOOOOOOOOOOOOOdc:oxkOOOOOOOOOOOOOko.    .':dxxxdddoolll. ...........                       ...                   ..'',,;;;'.;coxxxdxxddddxxxxxxxxx    //
//    OOOOOOOOOOOOOOOOOOkddkkOOOOOOOOOkoolccc'    .;cllccccc::c:;.                                                                      'oxddxddooodxxxxxxxx    //
//    OOOOOOOOOOOOOOOkkOOOOOOOOOOOOOOkl,'.....    .',,,,'........                                                                       'oxxxxxdddodxdxxxxxx    //
//    0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdcc:,.....  ........                                                                          .'..ckkxxxkxxxxxxxxxxxxx    //
//    00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkddddl:;ldolcll:;;;;:;;.  ..                                                             .;c;;okkkkxxxxxxxxxxxxxxx    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkOOOOOOOOOOOOc. ';''.    '.    .            ..''','',..                            .lxxxkkxxxxxxxxxxxxxx    //
//    OOOOOOOOOOOOOkxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOOOOOOkkOOOOo,';cll;'.  .. .',;'''.       .:dxxkkxoxdo:.            'll::::::ccc::cdxxkkkxxxkxxxxxxxddx    //
//    OOOOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOdlxkdcoodd;... .',',:;.       .cxxkkkkxkkOx'   .        :xxkkkkddxxkkkkkxxxxxxxxxxxxxxxxxxx    //
//    0OOOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOko::ldc... ....,::.      .'coxkkOOkkkkkc. 'l,      ,dxxkkkxodxxkkkkxxxkkkkkxxxxxxxxxxxx    //
//    0OOOOOOOOOOOOOkkkOOOOOOOOOOOOOOOOOOOkOOOOOOOOOOOOOOOOOOOOOOkxxkkc.  ..        ':,'.     ,clxddxxkkxdxOd::od:,,.';;okkkkkkxdxkkkkkkkkkkkkkxxxxxxxxxxxxx    //
//    0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOOOOOOkkOOOkkxddxd,        ..   .;'.... .;odkkxkkkkkkkkkdxkkdlddcdo:dOkkkkkxxkkkkkkkkkkxxkkxxxxxxxxxxxxx    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxkkkkxxddddd:.  .......   ....... .',,,;::;'',,'''''''',,''''';;;,;ccc:ccloodkkxxxxxxxxxxxxxxxxxxx    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkxxdddddoddocll:;;'..                                                             ...lxxxxxxxxxxxxxxxxxxxx    //
//    0OOOOO0OOO0OOOOOOOOOOOOOOOOOOOOOxollcllolllcc:;,;::cc::;;::;'..                                                                  ;xxdxxxxxxxxxxxxxxxxx    //
//    OOOOOOOOOOOOOkkkOOOOOOOOOOOOkOOxc,,;,,::;;'.....','.''...'.                                                       ..............'okkkxxxxxxxxxxxxxxxxd    //
//    OOOOOOOOOOOOOOkOOOOOOOOOOOOOOOOOxolcccccc:;,'....,,,,,,,,,..                                                   ....';cclolooodooxkkxxxkkxxxxxxxxxxxxxo    //
//    OOOOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOOOkkkkkxxxd:cooooddolcc,....                                                       .....'''cxxkkxkkxxxxxxxxxxxxxd    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxl:c:'...',,';lc'..          ....      ..,''.          .,'..     .,;;;;,;;;;,,,'',,lxkxxkkkxxxxxxxxxxxxo:    //
//    OOOOOOOOOOOOOOOOOOkkkOOOOOOOOOOOOOOOOOOOkOOOkx;.   ...'.''',.             ..       .,;:;,'        .':l;'.   .':dxxkxxxxxddxkxxxkxxxxxxkxdxkxxxxddxdo;.    //
//    OOOOOOOOOOOOOOOOOOOOOOkOOOOOOOOOOOOOOOOxoxxkx,     .,;'..',.              ...       ,lc:;'....,.';cdl'      ,;,,.,xkxxkxdoxxxxxxxdxxddxxool;.........     //
//    OOOOOOOOOOOOOOOOkxxkOkdddkOOOOOOOOOOOOOkkkxkk, .....','...,.              ..   ...';okkkkdlcclc:lxdoc.      ...'.,dkooxxdddxxdxkxxxxxxxxdo;.              //
//    OOOOOOOOOOOOOOOOxdxOOOkddkOOOOOOOOOOOOOOOkkkOl;lclddo:,..';.                .. .llodxxxkkxdlloc,,;coc.  ....:;,ldxxkxodkkddxkxxxxxxxxxxxxkc.              //
//    OOOOOOOOOOOOOOOOkxkOOOOkkOOOOOOOOOOOOOOOOOOOOdlxddxdl:.  ..                    .',:odxkOxdddl;.   :xc',cdoclkkxkkkkkkxc;lodxxkkxxxxxxxxxxxdl::;,'..       //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOOOOOOOOOOOkxdoccol,.                           .;::oxxooo,     .,;okkxxdoxxxOkdxxxd:',dkkkkkkxkkkkkkxxxxdxkxxxoo;.     //
//    OOOOOOOOOOOOOOOOOkxdkkkOOOOOOOOkkkkkkkkkkOOOOko,.......'..                           .;cllc:.      .lkOOkddxkkkkkxxdddlodxkkkkkkkxxxxxxxxxxxxxxxxxxdoc    //
//    OOOOOOOOOOOOOOkkkxlloclolllc:;,,,;;;:oxkkkOOOOo.    ..'...................      .'...':lo:,,.     .,lxxodlcdkxkkkkkxxxdxkkkkkkkxxxxxxxxxxxxxxxxxxxxxxx    //
//    OOOOOOOOOOOOOOOOOd:cc;,,,;;'..  .....,clllclxxc'    ..      ..............   .......,;lc:,',.   .;:codxdddoddxkxoxkxxxxxxdodxkkkkkkxxxxxxxxxxxxxxxxxxx    //
//    OOOOOOOOOOOOOkkxxdc:;,,,',:;,..........'''.,olc:.   ..                 ...  .....  .ldool::,.   'lccllxkkddddxkkxkkxkkxxxooddxkkxxxxxxxxxxxddxxxxxxxxx    //
//    OO0OOOkxxxdoooolool;',;;'.''....'....',,,',cxxddc''',,....  .     ...,...    . .. .;dkxxoc;;.   .'cdloxkkkxxkkkkkkkkkkxxkkkxxkkxxxkkxxxxxxdoddlloodddx    //
//    OOOOOOkxxxddxkkxkkxoc:;;'',,',;;;'..':cldolxkxdoc;;:c:,',;,;;.   .. ..;;. .....';:lxkkkxl::,.     'lxkkkxxddxxkOkkkkkkkkkxkxxxkxxkxxkxxxxddool;,;::;''    //
//    OOOOOOOOOOOOOOOkOOOOkdc::oxdclocloolcldxkOOOOo;.   .':;;::ccc,.      .........',,;okkkkkkxo,    .',lkOkkkxdllkkkkkkxxxxxxkkkxxkkxkkxxdl,....              //
//    OOOOOOOOOOOOOOOOOOOOOOdllxOkxxddOOOOkkOOkkOOkd;.   .,:::c:::l:. .',,,;:,,,'.'..;lldkkkkkOkd:.   .:odkkkxxdd:cxxxxkkxxxxdxxkkxkkxxxkd:.                    //
//    OOOOOOOOOOOOOOOOOOOOOOOkkOOOOOkkOOOOkOOOOOkko,.   .,cc;'....... ....  .;,;:;;;:okOkkkkkkkkxc.   .:dkkkdldkd:lkkxxxkkxodkkkkkkkkkkxc'.                     //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOkOOOOOOOkko,'.  .,:;,,,,;;,,'''.''  'ldoddxkkkOkodOkkkkkxc....,clddoodocc::dkkkkko,;dxdxxxkkkxd;                        //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOkxd'  .,:;;:cccccc:::;;,.  ....':kkkOkdxOkxkkxxo::looxxdooxdodxc;dkkkkkc..okxxxxkkkxxl;','.''.........        //
//    OOOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOkxdx:. .':;;::ccc:;,,'.....,'..:odxxdoodkkkkxxxxxo,.:dkkxddxkddxdoxkkxkkkdoxkkkxxxkkkkxkxxxxxxxddxddooollc;    //
//    OOOOOOOOOOOOOOOOOOkOOkxkkOkkOkOOOkOOkOkxxkkl,...   .,,;;'':c;.      ..............'lddxxkkold' 'lkkdxkkkxdxddkkkkkkxxdxkkkxxxxkxxxxxxxxxkxxxxxxxxxxxxx    //
//    OOOOOOOOOOOOOOOOOOOkOx::xOkOOxddxOkxkOxxkkol:.    .';;;'.''''....  .',,';clcccoloolxkkkOkxdc;..:dkxodxkkxodddkkxkkkddxxkxxxxxkxxxxxxxxxxxxxxxxxxxxxxdd    //
//    OOOOOOOOOOOOOOOOOOOkOkc,oOOOOkxddkkxkOOOkkdl,    ..';;c,... ..  . ..:xxdxOOOOxxdodxkOkkOOkxdoc:dkdolodkOkdxxxkkxkkkddkxxxkxxxxxxxxxxxxxxxdxxxxddxdlodx    //
//    OOOOOOOOOOOOOOOOOOOkkkc.,ooolll::lc:dOkkkkkd:.  ......'.,;;;;,...,cldxxkOkl:;,,c::oxkOkkkkxxd:.ckddkkxxOkxkkkkkkkkkxkkooxkxxxdxxxxxkkxxxxxxxxxxxxxddxx    //
//    OOOOOOOkxkOOOOOOOxlc:,.......       :OOkkkkxl;. .,'. ...;ccodod::xxdxkkkkx:.   ...:dkOkkkxddl. ,xkkkkkkkkkkkkkxxkkkxkkddxkxxxddxxxxkxxxxxxxxxxxxxxxxdd    //
//    OOOOOOOkkOOOOOOOOxdoll,;c,.        .oOOOkkd:c:. ':;. .... .'..cccxl.':lc'..       ..';;,:oddd' 'l:ckkkkkkkkxxxxxxkkkxxxxkkxxxxdxkxxxxxxxddooooodddxxdl    //
//    OOOOOOOkkOOOOOOOOOOOOOllkdl:,',,,:lxOOOkOkxdxc. ';;,.         .coo'                   .;cdkkd'  ..,dkxkxc;ldxxdooxddxkxdxxddxxoodxxxo:,............''.    //
//    OOOOOOOxxOOOOOOOOOOOOOdokOkOkkOkkOOOkOkkOkkkl,. .,;;.        .:dxc.                  .lkkd:..     'odxkx;.cxxdoodddxxdlcoxxxxxddo:'''.                    //
//    OOOOOOOolOOOOOOOOOOOOOdcdOkOOOOxkOkOOkOOOOOko:. .,;,..      .;codoc,.              .'cdkkc.      .cxxkkkdodxddxxxxkxxolldxxxxxxxdc'..............''',,    //
//    OOOOOOOdoOOOOOOOOOOOOOxdkOOOOOOOkOOOOkkOOOOkd;.  .;;,;'..   'dxxkkxo;;:;:,   ..   .;okkkOo..;.   ,xOkkkkkkkkxxkkxxxxdxxxxxxxxxxxkxxddddddddddxdllodxxx    //
//    OOOOOOOxdOOOOOOOOOOOOOOxkOOOOOOxdkOkOOOOOOko'     ';:;'.....:dxOkkxxxxxxx:   ':,..'lkOkkkko;ldc;.;xkkkkkkkkkkkkkxxkkxxxxxkxxxxxxxxxxxxxxxxxxxxxxdooddd    //
//    OOOOOOOdlxkxxdxkOOOOOkkxxxxxkOOddkkxkOOOOOx;     .,,,;;,,,..lkkkxxxkkkkOd. ..cxo;''ckkkOkOd''oxdlokkkkkkkkkkkkkkxxxxkkxxxxxxxkxxddxxxxxxxxxxxxxxxxxddx    //
//    OOOOOOOd:::;,,:dkkOOOd;:dxxkOkx::xkkOOOOOOx'     .,;,;;,,,..lxxkkxxOkxkOx;;loxkdoc;cxkkOOkkdoxdlxOkkkOkkkdoxkkkkkkkxxxxxxxxxxxxdddddxxxxxxxxxxxxxxxxxx    //
//    OOOOOOOo::,',;lxkkOOOxc:dkkOOkxookOOOOOkOOx;   ..';;'',.... .';,,,,,;;,,,,,;;;,'.....,,,,,,,,,..';;,;;:;;,,:ccllcc::loooddodxxddddxdddxxxxxxxxxdxxxxxx    //
//    OOOOOOOdokkxxkkOOOOOOOOkOOOOOOOdlxOkOOOOOkk:........                                                                  ................';;;;:ccloodxxxx    //
//    OOOOOOOxxOOOOOOOOOOOOOOOOOOOOOxccxxdolc:;'..                                                                                                   ..cxxxx    //
//    OOOOOOOxxOOOOOOOOOOOOOOkOOOOkOxc,'..                                                                                                             :xxxx    //
//    OOOOOOOdokOOOOOOOOOOOOOOOOOOOOk;                                                                                                                .lxxxx    //
//    OOOOOOOl,cdkOOOOOOOOOOOOkkkOOOk:                                                                                                                .oxxxx    //
//    OOOOOOOc.'ckOOOOOOOOOOOkkkOOOOOxlc,                                                                                                             ,odxxd    //
//    OOOOOOOc.,okOOOOOOOOOOOOkOOOOOkkkOc                                                                                                            .'ldxxd    //
//    OOOOOOO: .'cdOOOOOOOOOOkkkOOOOOkkO:                                                                                                              ;dxxx    //
//    OOOOOOO;   'okOOOOOOOOOOOOOOOkkkkk:         ..,,,;;;:'  .,;',:::;::::;;:;;;;;;,'...........                                                      :xxxx    //
//    OOOOOOk;  ,okOOOOOOOOOOOOOOOkkkkOk:.'.',;;:ldxkOOOkkxc..cddloxkkxxkkkkkOOkOOOOkdc:ldddxxxxddoollllcccc:::;;;;;,,,,''''...........              .;oxxxx    //
//    OOOOOOk;  .lkkOOOOOOOOOOOOkkkkkkOkxkOkkOOOOOkkOkOkkkxxo,;ddddxkkkkxxkkkOkkOOkOkc. .;cdkkkkkkkkkkkkkkkkkkkkkxkkkkkxxxxxxxxdddddddooolllcccc:;:::ldxxxxx    //
//    OOOOOOO;.,lxOOOOOOOOOOOOkkkkkkkkOOOOkkOOOkkkkkkkkkkxkkkccxkkxkOkkxdxkkkkkkkOOxc..;oodxkkkkkkkkkkkkkkkkkkkkxxxkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdxxxx    //
//    OOOOOOO;,xOOOOOOOOOOOOkkkkkkkkOOkkkOkOOkkOOkkkkkxkkkkkOd:dOOkkkOkxxxkkxxxkkxkd' .:oddxkxxxxkxxxxkxxOkkkkkkkxkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdodxxx    //
//    OOOOOOO;.lkOOOOOOOOOOOkkkkkkOOOOkkkOkkkOOOOOOkkxxxdooll:.':;,'''..............    .............',,;::codxxkkxxxkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdxxxx    //
//    OOOOOOk,.oOkOOOOOOOOOOkkkkOOkkkkkOOkxdolc::;,'......                                                   ...;coxkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxx    //
//    OOOOOOx'.dOkOOOOOOOOOOkOOOkkkkOkl,'...                                                                   ...:oxkxxxxxxxxxxxxxxxxxxxxxxxxxdxxdddxxxxxxx    //
//    OOOOOOk;'xOOOOOOOOOOOOkkkkkkkOOl.                                                         ....';;;;;;cccldxxxxxxxxxxxxxxxxddxxxxxxxxxxxxxxxxxxdxxxxxxx    //
//    OOOOOOOc'dOkOOOOOOOOOOOOOOOOOkk;                                                        .,;:clddxxxxxkkxxxkxxxxxxxxxxxxxxdxxxxxxxxdooddddxxxxxxxxxxxdd    //
//    OOOOOOOl,dOkkOkOOOOOOOOOOOkkOOkc'.............                                           ....',;;:::okkkkkxxxxxxxxxxxxxxxdxxxddxdddoccodxddxddxdddxxxd    //
//    OOOOOOOl;dOkOkkOOOOOOOOOOOOOOOOOOkkxxxxxxxxddddollllllllloooooolllc::llcc:::::::,.  .;::codxxxdcldxxxxkkxkkxxxxxxxxxxxxxxxxxxdoddddlloxdolldxxxdddddxx    //
//    OOOOOOOdcxOkOkkOkkkkkkkOkkOOOkOkkkkkkkkkkkOkkkxdolc:;'....;cdkkkkkkxdxkkkkkkkkkOc.  .,;:::;:c;.  'ldkkkxkkkkkkkxxxdxxxxxxxxddo;'cocccodlcc:oxddddddxdd    //
//    OOOOOOOxlxOOOOOOkkkkkkkOOkkOOkkkOkkkkkkkxddc'...         ,oxkkkkkkkkkkxxkkkkkkkkl..  ..           'lxxxxkkkkkkkxxxxdxxxxxxxxdo, .'...;c;...ldlcoooxxdd    //
//    OOOOOOOkoxOOkkOkkkkkkOOOkkkkkkkkkOkkkddo'...  ....   .''':oxxxxxxkkkkkxxkkkkkkkkd:........',;;..'cdxkkkxxkkkkkxxxxxxdxddxxxxdc.       .    .;..:oodddd    //
//    OOOOOOOkxxkkOkkkkkkkkkkkkkkkkkkkkkkkkood::l:;cl:.    ,ll;:cldxdodkkkkkkkkkkkkkkkxolodddxkkkkkkdodkkkkkkxxkkkkxxxxxddddxdooc;..                 .;ldddo    //
//    OOOOOOOOOkOOOkkkkkkkkkkkkkkkkkkkkkxxkdoxxxkkkkkkdcccldxxddxxkkkxxkkkkkkkkkkkkkkkkkxkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxo;.'odoc'                      'ldddc    //
//    OOOOOOOOOOkOOkkkkkkkkkkkkkkkkkkkkxxkkdlokkkkkkkkkkkkkkkkkkkkkkkkkkkkxkkkkkkkkkkkkkxkkkkkkkkkkkkkkkkkkkxkkkkxxxxxx:. .lxdl,                    ...:lodo    //
//    OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxkkkkxxxxxxxl'.,lxxxl;'',;,.''.....';;;:cooddddxx    //
//    OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxkkkxxxxxxxxxxxxxxxxxxxxxxxxxxddxxdxxxxxxxxxxddd    //
//                                                                                                                                                              //
//    JakNFT // static                                                                                                                                          //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JakNFT is ERC1155Creator {
    constructor() ERC1155Creator() {}
}