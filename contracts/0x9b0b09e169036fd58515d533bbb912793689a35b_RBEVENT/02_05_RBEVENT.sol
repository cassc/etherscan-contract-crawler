// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rogue Bunnies Event NFTs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllcc::::::::::cccllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllcc:;;;,,'............'',;;::cllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllcccc:;,'...........................',;:cllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllc::::;,,,''...........................''....',:clllllllllllllllll    //
//    llllllllllllllllllllllllllllllc:;;;;;,,,,''''''''''...... ..  ... ..    ...''''...';:cllllllllllllll    //
//    lllllllllllllllllllllllllllc:;;;,'''''''''''.'''''''''....... ... ...       ...'.....';cllllllllllll    //
//    llllllllllllllllllllllllllc:;,,,''''..................''.''.....  .''.       .. ..','..':cllllllllll    //
//    lllllllllllllllllllllllllc:;,,'''',:loddxxdoolc;'.......''''..'.. .';'.      .'.  ..','..,:lllllllll    //
//    llllllllllllllllllllllllc:,'''',cdOKXNNNNNNNNXXKkl:,.....''''',,.  .;:'.     .,;.   ..,;'.';clllllll    //
//    llllllllllllllllllllllllc;,,,,:dKXNNNNNNNNNNNNNNNXX0o,....'''',;.   .:c,.     ':;.    ..,,..,cllllll    //
//    llllllllllllllllllllllll:,',,cOXNNNNNNNNNNNNNNNNNNNNXk:'..'.'',;'.  ..:c:..   .;c,. ... .,;'.,:ccccc    //
//    lllllllllllllllllllllccc;,'':OXNNNNNNNNNNNNNNNNNXXXXXXOc,'''',,,'.   ..;cc,.  .,c:.  ..  .,;..,:cccc    //
//    ccccccccccccccccccccccc:;,',dXNNNNNNNNNNNNNNNNNNNXXXXXKkc,,,,,'''.     .;cc;. .':c'       .,;..,cccc    //
//    ccccccccccccccccccccccc:;'':kKXNNNNNNNNNNNNNNNNNNNXXXXK0Odlc;,'''.      .,:c;..':c'.       .;,..;ccc    //
//    ccccccccccccccccccccccc:;,cx000XXNNNXXNNNNNNNNNNNXXXXKKK0OOdc:;''..   ....'::'.'::'   ...   .;'.':c:    //
//    ccccccccccccccccccccccc::;oO000KXXXXXXXXXXXXXXNNNXXXXKKK0OOd:;;;,..    ..;,,;'.':;. ..;,.   .,,..;::    //
//    :::::::ccc::::::::::::::::lk00KXKKKKKXXK0OOkkxkOKXXXXKKK0Okdc;::,.      .':;'..';...';:'.    .,..,::    //
//    ::::::::::::::::::::::::c::dOOKK00KKKXXOc;,;ccldOKXXKXKK0kkkl:::,.       .;:,......,::'. ... .,..'::    //
//    ::::::::::::::::::::::::c:,cxOKK000KXNNKklcoxooOKXXX0xocclxkoc:;'.       .;:,....';;,....,.. .'..';:    //
//    ::::::::::::::::::::::::c:,,cO0OOO00KXNNNXK000XNNNX0l;:,'cxxoc:,.       .,;:,...,,,....,;,.  .'..';;    //
//    ::::::::::::::::::::::::cc;;d000OOO00KXXXXXXNNWWNXKOxxdoooodo:,.....  .',;;;'.......';;,'.   .'..';;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;:cldOO0KK0OO00KKKXXXXXXXXK0OO0Oxdoddl;,'.    .';;;;,. ...',;;,..     .'..,;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;,:dkkOKKKK000KKXXXXK0000OOkOkdoddl;'....    .,;;,....',,'.......  .'. .,;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;,. .'cdxk0XXXXKXXXXXXXKOkxddxxddddlc,.       ..,'.............''..  ....',,;    //
//    ;;;;;;;;;;;;;;;;;;;;;;,'.   ..':ldOKXXKKK0Okkxddooodxxdxxdl:.      ..',,. .....''',,''..   .....,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,..     ....':d0XKKK0OOkxdoodxkkxdxdc;.  ...  .',,,............      ... .',,,,    //
//    ,,,,,,,,,,,,,,,,,,,,'..      ...  ..:x0KKXK0Oxddxkkkkxxoc;.  .',.    ..''........        ... .',,,,,    //
//    ,,,,,,,,,,,,,,,,,,'...        ..    ..:dkOOOkxxkkkkkxdol:,....','....   ....            ... .',,,,,,    //
//    ,,,,,,,,,,,,,,,,'...          .,.    .,dkxxxxkkkkkkxoodd;.....''.....                 ... ..'','''''    //
//    ,,,,,,,,,,,,,'.....    ..      ..    .,lxxkkkkkkkxxdxxxl.     .'.                   ...  ..'''''''''    //
//    ''''''''''''....,,.   .''.             ..'',;:ldxxdxkxo;.     .'.     .            ..  ..'''''''''''    //
//    ''''''''''... ....    ...                      ..;clddl'.     .'.                    ...''''''''''''    //
//    '''''''''..          ...                   ..';'.   'lo'      ...                  ...''''''''''''''    //
//    ''''''''....         .                      .'::.    .:,.                       .....'''............    //
//    ''''''''....       .                        ..:c...;,..'.                   ........................    //
//    ..........         ..             .           'ollxo. ',.             ..............................    //
//    .........          ...                        .cxo:. .;c;'..........................................    //
//    .........    ..     ....    ..              .',;:;,,',:::;;,,,'.....................................    //
//    .........    ...    .,:l,  ...    ..         ..........';:cc:;'.....................................    //
//    ..........    ..    .,ld:. ....   ..                    ..,;,.......................................    //
//    ...........   ...    .:c'  ....         .    ..             ............................',,,,,'''...    //
//    ............        .';'    ...        ..    ...       ...   .......................'',,;;;,',,'....    //
//    .........  ..       'odl.    .         ...             ...   ....................'',,;;,'''.........    //
//    .........   ..      ,dxo.             ..'..                  .....................''''..............    //
//    ..........   .      .,;'              ........              ........................................    //
//    ............                          ...   ...            .........................................    //
//    ...........                           ...    .            .........................;:;,,;'''.;:;:;..    //
//    .........                              .      .          ..........................,;,;;;,,,';:,;;..    //
//    ..........              .    .         ..........        ...........................................    //
//    .............  .        ...  ..        ............      ...........................................    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RBEVENT is ERC721Creator {
    constructor() ERC721Creator("Rogue Bunnies Event NFTs", "RBEVENT") {}
}