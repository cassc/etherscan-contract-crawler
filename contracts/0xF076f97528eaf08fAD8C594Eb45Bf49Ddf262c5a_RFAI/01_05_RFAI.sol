// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RetroFutureAI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''........''''''''''''''''''''''''''''''''.......'''.''''''''''    //
//    ''''''',:cclooccc:,','.......'..''..'''.'''.''.......',,,:cccoolcc:,.''''''    //
//    ''''';cdxxkxxxxxxxdddl:;,''...,,;;;;;;;;;;;,,...'',;:ldddxxxxxxkkkkdc;'''''    //
//    '''.;dkxddoododxxxxxxxxxdolc,'';looddxdddol;'',clodxxxxxxxxxdodoodxxkd;.'''    //
//    ''''cxdlllxO0OOkxoddxxxxxxxxdl:;lxxxxxxxxxl;:loxxxxxxxxddodkOO0Oxllldxc''''    //
//    ''''ld:;:loxKXK0XKkdooxxxxxxxxxddxxxxxxxxxddxxxxxxxxxdodkKX0KNKxol:;:dl''''    //
//    ''''co;':c;okxlx00XNkodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdokNX00xlxko;c:';o:''''    //
//    '''.,lc:c:ldl;;ccdO0xooolc:ccldxxxxxxxxxxxxxdlcc:clooox0Odcc;;ldl:::cc,.'''    //
//    ''''.,:c:cc:,,',loooccc:;;:;;:;;:coodddooc:;;::::;;:cccoool,'',:cc:::,.''''    //
//    ''''....;lll:;,;oddl;;;...'..':;'',:cc::,'';:'..'...;;;lddo:,;:lll;....''''    //
//    ''''....';ldddoooddl;;;.     .;;',::;;;;:,';;.     .;;,lddooodddl;'....''''    //
//    ''''''''''',:ccloddlc:;'....';cc:;;:oxo:;;:cc;'....,;:clddolcc:,'.'''''''''    //
//    '''''''''''.,ccloddc;clllllllol::;;dKXKd;;::lolllclllc;cddolll;.'''''''''''    //
//    '''''''''''.;oo::okd::oxxxxollc::;;o0K0o;;::cclodxxxo::dkoc:oo;.'''''''''''    //
//    '''''''''''''cddoldxolodddxxxxxl:;,:lol:,;:lxxxxxdddoloxdldddc'''''''''''''    //
//    ''''''''''''.;oxdlcccloxxxxxxxxl:;',,,,,';:lxxxxxxxxolcccldxo;.''''''''''''    //
//    '''''''''''.;lcclclccldxxxxxdddl;'..,,'..';ldddxxxxxdlccccllcl;.'''''''''''    //
//    ''''''''''''':dl;,;looxxxxxxo::cc::::c::::cc::oxxxxxxool;,;lo:'''''''''''''    //
//    ''''''''''''.';coo:;;:loddxxdccx0KKXXXXXKK0xccdxxdddl:;;:ll:;'.''''''''''''    //
//    '''''..''',cllc:codolcclodxxxxoodxkkOOOkkxdoodxxxdolcclodlc:cll:,'''..'''''    //
//    ''''',:oddxOkxxxdccoolooodddxxxxdolllllllodxxxxdddooolooccdxxxxddool:,'''''    //
//    ''';ldkkkxxxxxxxxxdol:clooolccooodxxxxxxxdooocclooolc:lodxxxxxxxxxxxkxl;'''    //
//    .,okkxxxxxxxxxxxxxxxxdoc::c:;,,,;:clooolc:;,,,,:c::coxxxxxxxxxxxxxxxxxkko,.    //
//    :dkxddxxxxxxxxxxxxxxxxxxxdolllcclodddddddoccclllodxxxxxxxxxxxxxxxxxxxddxkd:    //
//    xxxdodxdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdxdodxxx    //
//    odxdoddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddooxdo    //
//    ldxddooxxxxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxxxxooddxdl    //
//    odxxdoldxxxxoc:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:coxxxxdlodxxdo    //
//    xxxxdlldxxxo;';dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;';oxxxdoldxxxx    //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract RFAI is ERC721Creator {
    constructor() ERC721Creator("RetroFutureAI", "RFAI") {}
}