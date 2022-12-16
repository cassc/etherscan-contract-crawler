// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Mortal Pose
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddddddddddddddddxxxxxxdddddddooddddddddddddddddddddoooo    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddddxxxxxxxxxxxxxxxxddddddddddxxxxdddddddddddddddoo    //
//    kkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkxxxdoloooooddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddd    //
//    kkkkkkkkkkkkkkkxxxxxxxxxkkkkkkkkkkkxol:,......'',:clodxxkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxdxxxxdddd    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxl;'..        .....';lxkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxddddd    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxc'..   ........',,'..,lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxdddddd    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOko,..:lloxkOkkkkOkkkxl,.;okkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxddd    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOx:''o000KXXKK0000kxxkx:',lkOkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxx    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOd,.,d0KKKXXXK00K0kxkO0k:':xOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxx    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOd,'lxkO0000000kxoc::lkKOllkOkkkkkkkkxkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxx    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOxcokl;,,,'',lc.......;d0Oxkkkkkkxxxxxxxxkkkkkkkkkkkkkxxxxxxxxxxxxxddd    //
//    kkkkkkkkkkkkkkkkkkkkxxxkkkkkkkkxdxkolccl:,,dx;,:lolldk0Ooxkkkkxxxxxxxxxxxkkkkkkkkkxxxxxxxxxxdddddddd    //
//    xxxxkkkxxxxxkkkkkxkxxxxxxxxkkkkdlx0000OOOxxK0xxkO00Okdkxdkkkxxxxxxxxxxxxkkkkkkxxxxxxxxxxxxdddddddddd    //
//    dddxxxxxxxxxkkkxxxxxxxxxxxxkxxxxlldxkO0K0xkK0xdxOOOkolddxOxxxxxxxxxddddddooodxxxxxxxxxdddddddddddddd    //
//    ooodxxddddddxxxxxxxxxxkxxxxxxxxkdc:coxOOkc','.'cddxdlllldxxddxxxxdl:;,,,,,,',,:loddxdddddddddddddddd    //
//    llloooooooddddxxxxxxxxxxxxxddxxxxl,,:ll:'...,'...',;c:;cddddddddl;'...'..''''..';lddooddddddxddooddd    //
//    llcllllloooooooooddoodxxkkxxdddddo:.....',:oddl:;.....,looooddo:'.........,:;...':oooooddddddddooooo    //
//    lccclllloddooooollooooddddxddddoool;.  .::,'',',;'....:ddooooo;.......:loxkkd:...'cdooddooddddoooood    //
//    oddocllloxxkOkxdollooolc;;:loooooloxl.  ....''.......,dOxodxxl,..''':d0XXK0kxxl:'':dkxddddddddoooood    //
//    dxdocclodddxkkddolllllcccclodolooooxxc.   ....  ....,cxOdokOkd:':lodxO00K00kxkOOkdloxxdddddddddooodd    //
//    :;:cldkOkdlcooolccccccclxxodO0kdooclol;..       ...';okkooddollclddxkOO00KOo::coOXKkoxkxdddddoodoood    //
//    :::codooolc::lcc::::::::clloxxoc:;,;cc:,...    ..',,cddccooolloxkkkkO00Oxc..';cdOKK0xkkxxdddddoddooo    //
//    ,oxxo:;;;;;;::::::;;;;::cccc:,''','';::;,'......';;cdxc,;:;;::lodOkolcccoc;cxO00Okkxdkkdddddoooooooo    //
//    lddo:;cc:;;;;::;:::clcclc:;,,'''..',;cc;;;;'...';loddocclollllc:;:;'.'',o0OO000Oxol:ckOdooddooddooll    //
//    lodxl::cloc;;;;;;cllodoc:cc:;,'.',coldkxdodo:,;cdxxdollcccclodxxdc;,,;;;ckkddO0Odc,';x0xddddddooolll    //
//    odkkdddlodd:,;:ccll:oxdodxxxdc:;,,ldc:looodkkxk00kddooodddddxkOO00d:;,,,,,'.':c:;,..;kK0xdoooooooolc    //
//    :ldxodOOOkxdool::;';:;;;:c::;,;c:,cxd;.....'coxOOkkO0KXXXXXNNNNNNNXd;,,,,'.',,,'....:x0Kkdddooloolc:    //
//    ::c:,;loodxxdc;,'.'''''''''''''''',co:''......lkxdxxOO0000000KXOkOK0c'''''':lol;...,cdxxl:cc:;;;::::    //
//    ,,'...'.,oxdc;,'.....''',,,''''...',;,,'.....:kOxl::cccccc:;;xd:cok0d,....';cloo;';clol:;;;'''...',,    //
//    '......'cdo:;,'.......',,,'''......,;;,,'....'cddxkxkkoc;,;cdxllxxOKKl.....';::od::loo:',,'.........    //
//    ..'....,cc:;'... .....',:l;,'',,...',;,,''...',..,:lo:;,,cxkl,,coodOk;... ..',;coo;;:,..............    //
//    .'.....:c;''...  . ...',dKxclll:'...,;;,,'''..:c;'':l,..  ...'c:.'cc,.     .',,;col:'...............    //
//    ....'';lc;'...     ...'':Okll:,,'''',;;;,'''.,xOxl;;ccc. ..'';l,,oo'       .,,'',cl:,,''............    //
//    .....':c;'....      ....'::,,:ldl,''',;;,,'..':dkoc::lxo;,codkOxdll;       ......,,'''..............    //
//    .'''',c:,...        ..:l;'''cOkddxxc'',,,''....:dkOOdclxkkkOOkxo:cc'       ......;;'........';::::;'    //
//    '','':xd:...        .:oOk;.cOx,..,xOl'',,'......':ll::x00Oo;cl:,,:,           ...;,.........,;:x0kdd    //
//    ,,,,'l0d,....        ..'dl,lk:....'ox;.'''......,oO00Oxdoc',ddc,';.          ...,c,............'ll,.    //
//    ,''..,c;.....          .,occko.....;o;..','''..',d00xc'...;dOd:,c;.        .....ck;.........c;..'.      //
//    ,,,,':oo:'...           .co,;xd,...lO:...'.'::,'.;oc,',;ldxxo;;cdl.     .....'..cOc.........:c'.'..'    //
//    ,,,',xKkl,,'..           .,' .oo'.;ko.  ...',,'..cOOOkOkxxl,;ldxxc.    ..,;;;;;,lOl. ........... ...    //
//    ;;'.;olc;;;,..   .       .'.  .okdkd'   ..'','...:dk0kdl::,,;cx0Oc.    .,;;;;;;;:dc.   ............'    //
//    ,''';;''',,,'.  ...      '. .;col::;.    .'','.  ..,ldoc:'.,,..;co:.   ..';;;;,'','.  ..............    //
//    ...,;'.''''... .....    .;::lo:.  ..    .cxxdl'     'ccc:cddoc. .',.  ..':llool:cl;.  .............'    //
//    ...,;;:cc:;;,......';;;:ldo;'.   ....  'd0XXK0x;    .:c:cooll:.  .'.  .',;::ddlcco:. ............ ..    //
//    ...,cooc;,,;,'...'cxOOOkxol;...'.',.. .,clooolo:.   'ccloc:c:,....,;....',;;cl:::c;. . ..........  .    //
//    ...cxxdl:;,....,lxxolllloddol:,......  .;,,;;;,.    'cldxxxdooc:cccl,....'',,,;;;;'... ...... .,. ..    //
//     .,xOkxdool::coxxdolcllloooll:'..       ......      .llodol::cc:ccclc'....,:cc:;,'.....    ..,::. .,    //
//     .ck00Okxxdooolllcc:;;:ccllooc'                     ,occolc:cclolllcc;.';coddl:;,,,....  ..,,....,;;    //
//    .,ldxxxxdol:::::;;;,,;;;,;;::,.                    .ldolc:;cllcccc:;,;:cllooccc:;;;.     .;,...','..    //
//    .;ccllool;,'''',,,,,;;;,,,;;;,.                   .;dxkxdol:::;;;;,...,cccc:::;,,,,.     .;:,,,.....    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract nrhmn is ERC721Creator {
    constructor() ERC721Creator("The Mortal Pose", "nrhmn") {}
}