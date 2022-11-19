// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Collaborative Remixes Signed Artwork
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    XXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNXNNNXXNNNNNNNNNNNNNNNXXNNXXXNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNXK0KXNNNNNNNXKK00O00O000KXXNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNXkc,...;lxxdolc:,,'',,'....',;:cldxOKXNXXXXXXXXNNNXXXXXXXXXXXXXNXXXXXXXXXXXXXXXXXXXXX    //
//    XNNNXXXNNNNNNNNNNNNNNNNNNNXNNNNXNXk;.     ......  ..........          ..;lxOKXNXXNXNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXNXXXXXXXXXXXXXXXXXXXXXNXXXNNNNKl.      .........      ...                .'cd0XNNNXNXXXXNNNNNXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXN0;    ............         .                    .:dKXXXXXXXXXNNNNXXXXXXXXXXXXXXXXXXXXNNXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXNKc..  ......'......                                 .ckXNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXNXOc.......'...... .               .                     .;xKNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNX    //
//    XXXXXXXXXXXXXXXXXXXNXKOxdxxdc'.......''.....       .....                               ;kXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNN    //
//    XXXXXXXXXXXXXXXXXXXXXOl'...... ......''....',:clodxxkxxdoc;...                          .xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXk:'..... ........;lxO0KKXXXXKKK000OOxddolc;'.                      .xXXXNXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXNXkc'..   ..  ..'oKNNNNXXXXKKK0K0000xdkOOOkdl;.                      :KNXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXX0dc,'.......'oXNNNNXXKKK00000000OkxO000Okkd:'.                    :KNXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXX0kdc;..'cx0NNNNXXXK0K000000OO000000OOOkdl,.....                .oXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOk0XKKNNNNXXXKK00OxxdxO0000kxkOOkxoc,..............        .ONXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNXXXNNNNXXKK0OOOk:,::cdkkkl,cxdlodl'.............          :0XXNXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNXXK0Okc;:;;'.,:;cdxdc;lo;,okkl...... .                :KNXXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNNNXXXXXXXXXXXXXXXXXXXXXXXXNNNNNXXXXK00OOOx:... ...'locldloxd:,cxOxlc;..                    .xNXXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNNNXXXXXXXXXXXXXXXXXXXXNNNNNNNNNXXXKKKKKOo:,..,,;lccc:cccll:;',clo:';;cl'           ...     ,0NXXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNNNXXNNNXXXXXXNNNNNNNNNNXXXXXNXXNXXXNXXXd',;..';:;;c;.',c:'.....;;...'cko.       .cx0KOo.  .xXNNXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNNNNNNNNNNXNNNNNNNNNNNNXXXXXXXXNXXXXXXNKl..'. .....',;:,;,.... .......,lxl.     .dNXXXXXx,'dXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNNNNNNNNNNXXXXNNNNNNNNNXXXXXXXXNNNNNXXN0:...   .....''''. ......,;'..':;l0O:.  .dXNXXXXXXK0KNXXXXXNNNNNNNXXXXXXXXXXXNXX    //
//    NNNNNNNNNNNXXNNNNNNNNNNNNXXXXXNNNNNNNXXNNd. ..;lloolllccccccc;'..',;,,;;.:0NKdcd0XNNNXXXXXXXXXXXNNNNXXXXXNXXXXXXXNXXNNNN    //
//    NNNNNNNNNXXXNNNNNNNNNNNNNNXXNNNXNNNNNXXXN0lck0KXXKK0OO000KKKK0Odc:;;;;,'.lXNXNNNXXXNNNNNNNNNXXXXNXXXXXXXXNNNXXXXXNXXNNNN    //
//    NNNNNNNNNXXXXXXXNNXXXXXNNNXXXXNXNNXNNXXXXXXXXK0Oxoc::;:cllodxxkkkkxo;...;kXXXXXXXNNNNNNXNXXXXNXXNXXXXXXXXNNNNXXXXXXXNNNN    //
//    NNNNNNNNNXXXXXXXXXXXXXXXXNXXXXXXXXXXXKKKKK0Oxoc;.....',:loodddddddxkxc''dXNXXXXXXXXXNNXXNNXNNNNXXXXXXXXXXXXNNNXXXXXXNNNN    //
//    NNNNNNNNNXXXXXXXNXXXXNNXXXXXXXXXXXXKKKK0OOxl:,,'...',;:lodxkkkxxdxxxkkxdkKNXXXXXXXNX0k0KXNNXNNXNNXXXXXXXXXXNNNXXXXXXXNNN    //
//    NNNNNNNNNXXXXXXXNXXNNNNXXXXXNNXXXXXK000OOkxoc:;,,'''',:clllcccclodxxkkOOkOXNXXXXXXOl..';o0NXXNXXXXXXXXXXXXXNNXXXXXXXNNNN    //
//    NNNNNNNNXXXXXXXXNNXXXNNXNNXNNNNNX0xxkxkO00Oxoc;,'....,;,,,,'''',:lxkkkOOOkkkOXXXXxc:,....,:dXNXXNXXXXXXXXXXXXXXXXXXNNNNN    //
//    NNNNNNNXXXXXXNNNNNX0XNNNNXNNXNNXx:,,,;cdOK0Oxoc;;,'...   .....,codxOOOOOOkxo;;cl:.     .'..oXXXXXXXXXXXXXXXXXXXXXXXNNNNN    //
//    NNNNNNNXXXXNNNNNNNNNNNNNNNNNXNNXKkdolcclk0Oxdooodxdoc:::::codxkOOOOOOkOOOkkkdc:,   ... .'.,ONNXXXXXXXXXXXXXXXXXXXXXXXXNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNK0XNNXKkdl:,ckOxoollodkOOOOOkkOOOOO0OOOOOkkkkkkkkxd:.  ..,'',';ONNNNNNNXXK0XXXXXXXXXXXXXXXNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNXXXNNXxc,'.,x0OkxolllodkOOOOOOOOOOOkkOkkxxxxkkxxxdl. .';,,::',xXXNNNNXNNXK0XXXXXXXXXXXXXXXNNN    //
//    NNNNNNNNNNNNNNNNNNNNNX0KNNNXNXKOl....'dKXXKOxdooooxkOOkkkkOkkkkkkkxxdddxxxdol;',::;,,,.'xXNXXXXXNXXXNNNXXXXXXXXXXXXXNNXX    //
//    NNNNNNNNNNNNNNNNNNNNNXXXNNNNNO:,..':cdkkxdoc:;:::lx00OOOkOxdolcldddxxxxxxdl:'.......';lOXXXNXXXXXNNNNNXXNXXXXXXXXXXXXNXX    //
//    NNNNNNNXXNNXXXNNX0KNXXNNNNNNXd.':lk0OOkl........:xO00OOOkkxl;;:odddddddddl;.     .cOKXXNNXXNNNNNNNNNNXNNNNNNNNNNNNXXXXXX    //
//    NNNNNXXXXXXXXXNNNXXX0KNNNNX0xc:xXNNXK00kl,..,lddk00OOOOkkkxxxxxddddc'.,lo;.      ;0NNXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNXXXXXXXXXXNNNXNNNNNXk,..dXXNOkXNXK0Oo::cldkOOOkkkkkkkkkkkxxdddo:,;c;.      .xNNNXXXNNNXXXXXXXXXXNNNNNNNNNNNNNNNNNNN    //
//    NNNNNXXXXXXXXXXNNNNNNXXXNOccd0XNXl.:OXKOl,'....',;::clodxxxxxddxxdddol;.        ,0NNNOlxKXXXXXXXXXXXXXXXXNNNNXXNNXNNNNNN    //
//    NNNNNNXXXXXXXXNNNNNNNXNNXNNNNNNXX0xx0XNx'.     ....';:clooooooodollc;...',',,,,;lOKXXx,;xKXXXXXXXXXXXXXXXXXXXXXXXXXNNNNN    //
//    NNNNNXXXXXXXXNNNNNNNX00XNXNNNNN0kKNXNNN0:.....',,,;ccllloollllclc;,....':c::cllcccldkkdlokKXXNNXXXXXXXXXXXXXXXXXXXXXNNNN    //
//    NNNNNXXXXXXXXXXXNNXNX00NNN0olkXNXXNNNNNNKd,......',;:clllcc:::;'..  .:lcllodxxddddooooodxkO0XXNNXXXXXXXXXXXXXXXXXXXXXNNN    //
//    NNNNXXXXNXXXXXXNXXNXXXXNNNk;'oXNXXNNNNNXNKl.':cllooooolc::;'...      .','',;;:::clodxxxxkO000KXXNNNXXXNNXXXXXXXXXXXXXNNN    //
//    NNNNNXXNNNNNNXXXXNNXNNXXNNXK0KXNNXXXNNNNNN0ddOOkkkxxdoc;'..          .clllllooodooolllldxxxkOO0KXNNNNXNNNNNNXXXXXXXXXNNN    //
//    NNNNNXXXNNNNNNNNNNNNNXXXXXXNXXNKll0NN0dd0NXkodooolc:;'..              ...',;::ccccodxxkO0OkOOOOO0XNNNNNNNNNNNNNNXXXXXNNN    //
//    NNNNNXXXXXXNNNNNXXXXXXXXNXKXNNNKxdKXOc,;kNNOc,'....                      .,:::::cll:::cloxxkOkkOO0KXNNNNNNNNNNNNXXXXNNNN    //
//    NNNNNXXXXXXXXXXXXXXXXXXXNNXNNNNNNNKd:',oKNNX0xol;..                       ':cloodxdddxxxkkkkkkxkkO00XXNNNNNNNNNNXXNNNNNN    //
//    NNNNNXXXXXXXXXXXNNNNNNNNXNNNXNNNX0o;',dKNNNNXNNNO:'..                       .....;loooodxxxkkkkxxkOO0OKNNNNNNNNNNXNNNNNN    //
//    NNNNNNXXXXXXXNNNNNNNNNNXNNXXXNXKOo;',dKK0kkOO00Oxolc:'.                          .lKK0kdllodddxkxdxxOO0XNNNXNXXNNXNNNNNN    //
//    NNNNNXXXNXXXNNNNNNNNNNNNXNNNXNKkdolloxdol;;:lllc:::cl:.                           .lKNXKkdoolcccllodkkkxOXNXNNNNXXNNNNNN    //
//    NNXXXXXNNNNNNNNXXXXNNNNNNNXXN0xdddxxdc;,,:ldxkkdlc:,'..                            .c0XXXXOdlc:;,,;lxdl,.l0NXXXNXXXNNNNN    //
//    XXNNNNNNNNNNNNNNNXNNXNNNNXNXOolodxkOkxoloxkxkO0Okxocccc:....                     .. .;OXXXXXk;.,'.',::,...cKNXXXXXXNNNNN    //
//    NNNNNNNNNNXXNNNNNNNNXNNXNX0xollccodxddollc:;:cccc:,,,;::'.                        .   .lOXXN0, ......'....;0NXXXXXXNNNNX    //
//    NNNNNNNNNNNXNNNNNNNXXXNXOdoollcclodxxoc:ldocclolcc;;:;,'..     .....              .     ':x0o.    ..''.  .lXNNNXNNXXNNXX    //
//    NNNNNNXNNXXXNNNNNNNNNNXkoloooc::oxkkxxddddddxkkxollool;....   ......                    . .'.       ..   .kNNNNXXXXXNXXX    //
//    NNNNNXXNNXXXNNNXNNNNNXkolccccc:coddoc;,;,'',:llc:;;;;;'...    .....           .         .   .            ,ONXNXXXXXXXXXX    //
//    NNNNXXXXNXXXXXXNNXNNKdclc::::::cdkkxdoooooccoxdoc;,'''....   ......          ......     .   ..           .xNXNXXXXXXXXXX    //
//    NNNNNNXXNNNXXNNXNXKKk:,:c;,'',,;;::;;;;:cllllcclc;,,''''...........          ... ..  ....    .           'kNXXXXXXXXKKXX    //
//    NNNNNXXXXNXXNNXXNXOx:..',''....''...........'cddlc:;,''','............           ........    ..  ....    .:xKNXXXNKddOKX    //
//    NNNNNNNNNNNNNNNXNXkl..'....'.... ..  ...    .cxkxdolc;,,,''...........          ...'''...    ...         . 'OWNNNNO,.l0K    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NOREM4 is ERC1155Creator {
    constructor() ERC1155Creator() {}
}