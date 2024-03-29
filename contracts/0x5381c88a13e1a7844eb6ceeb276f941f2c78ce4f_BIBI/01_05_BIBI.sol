// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ✿ bibi flowers ✿
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//       .....    ..........................   ....... ......  .....  .....  . ...       //
//     ...    .'..   ':,....','      ,l,  .,:c,      ':.    .;,'..,;,.   .,,.    .,.     //
//     ...;. .;c;,'.,::.     .,.   .':c;'':cloc'.  ..;l;'.',c:......::'..;cl,  .cc;.     //
//      ..;ccc:'.........  ...;c:,;c:,........'::,;:;'...','....  ..''''''',::,::'.      //
//      .......          ..    .....    .       ...     ...      ..     .   ........     //
//     .''   .,'                                ..                         ..     ''     //
//     .,''..,:'                           ..''...'.       ..              ':,...,;,     //
//      .......                           .,..    .,.  .'.....'.           .'''.',..     //
//      ... ...               ........   .,.      .;'.,..      ',           .. ..,'      //
//     .....  ,'             ',    ..'''':'       .cc'         .;.         .;..',,;'     //
//     ...'''';.             ,'        .;c.       ';.          ';.         .'.....'.     //
//      .....'.              .;.         ;'      .;.          ';.           .....'.      //
//     .;,..';:.              .,'        ,:'.....:,         .,'             .    ...     //
//     .......'.               .',''.  .''...... .''.    .';;.             .,.  .';.     //
//     ...   ..         .........';ccc:'           .',''';;'....''.        .,;'';,.      //
//      .'.....       .'...         .l,              ;;.         .,'        ........     //
//     ..    .;.     .'             , 000c      000c.;.            ',      ...   .''.    //
//     ...',,,:.    ''              ' '              ;.            .,.     .;....,...    //
//      .'''''.    .,.          ..',;l:.''''''''''' .::..          .'       ........     //
//      .......    .,.      .'.';lc;..'.          ......''.    ...'.        ........     //
//     .,.  .',.    ',. ..''...''.     .''.......,'.     .,;,.....        .;,    ...     //
//     .''...,,.     .'.... .',.        .:'.....';.        .'.            .::'.';;'.     //
//      .....'.            .;.          ,'       ',         .,.            ..''.''.      //
//     .........          ',.          .,.        ,.         .;.            .....':,     //
//     ':'. .','         ',           .c'         .;.         ',           'c:'.';:,.    //
//     .';,''''.        ';.          .oo.         .c;         .,.          .'..   ...    //
//       .'..',.       .;.           :d,           :o.         ,'           .....,,.     //
//      ..   .:;.      ,,           ,::.           'l;.        ,,           ....',,.     //
//     ....',';,       ,.          ,'';.           .;;,        ,'          .'','.  .     //
//      ........       ''        .,. .;.           ''.;.      .,.          .... ....     //
//      .......        .'..........   .,.        .',. .,'.  .''.            .....'..     //
//     ..     ..         .......        .........'.     ......             ..     ..     //
//     ,;'..;:;.                                                           ':,..',;,.    //
//     .;:;;:,.                          ..                             .   ';;;::,.     //
//      .....'.......................................... ...... ............''.','..     //
//     .......,;.    .,'...,;;;;,..',,.     ':'.,'..:c.   .::.    .:l,.''';:,..'.. ..    //
//     ..     ';,'..,:;,'....,. .....;;,..;c:;. ..';cc:,',:c;'...';,'.   .,'       .     //
//      ...... ....... ...............';,,;'.  .....  ......  .....  ........     .      //
//                             ....     ..              ..                               //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract BIBI is ERC1155Creator {
    constructor() ERC1155Creator(unicode"✿ bibi flowers ✿", "BIBI") {}
}