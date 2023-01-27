// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BOBO BALLOON
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWNWBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWNXK0OOOOOkkxdolco0WBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWKkkxdllxxd::l;''....,oKWBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOWXkkOdokO0dlk0kl:loccododkKWBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWWNXK000OOO00KXNWBOBOBOBOBOBOW0ddxd:oXX0x:cdxdoolc:coxkXWBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWX0kdolc:;,.........''',:ld0NBOBOBOWOllONW0ccddxxxxxo::lxxdoxXWBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOWXOoc,'..             ...'''..  .,ckXBWKxcc0XkdodkOxxxxxxkxoclx0NBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBW0o;..                      .....     .,ldx0xcooodxxxolldkOkxxk0NWBOBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBNk:.                                     .ckOxl::cldk0K0kdlldOKWBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWO:.                                     .;oooc:lolccclxxxk0NWBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBONd.                                     .':lc:;,',cdxxk0XWBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBXl.                                     .'::;,.    .kWWWWWWWWWWWNNNNWWBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBONl.                                    .';:;.   .....:lcccccccc:::;;;clodxO0XNWBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOO'                            .........';,......                       .....,:ldkO00XWBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWo.             ...           .. ...                                             ....,xWBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOWWNK0d.      .........            ..                                                      .xWBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWNXKOdc;,''...........                   .                                                      .oNBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWX0kxolc;''.........                                                                                    ;XBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBNKOxlc;,...  ......                                                                       .......            .xBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOWWNXKOxoc;'......                                                                               ....',,'.'..          lNBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBXkddddoc:;;'......                                                                                    ...';cool;...         ;KBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBXd:'.....                                                                                            ..':loooool'..        .xWBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBWN0xl:,.                                                                      ............''''.......:ooooool,.'.,::;,'',dNBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBNKOxolc;'..                                                ..........'''''''''''''''''''''''''.',coooc,',':x0XWWNNWBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOWNK0000Okxddoool;...   ..........................''''''''''''''''''''''''''''''''''''''''..,;;'';ckNWKOXBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBONk;''..'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..'''ckXXOONBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOKo,''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.;xKKNBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOB0;.'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''cKBOBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOXo''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''lXBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBNd''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',xWBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOB0;.''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.oNBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOB0:.''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.cXBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBO;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.:KBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBONo''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.:KBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBO0;.'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.cXBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBONd''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.oNBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBNo''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''xBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBNo''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.:KBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBNOc'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.lNBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWO:''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''xWBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBONx,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.;0BOBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWx'.'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''...,dNBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBXc.....''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''......'',xWBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBNo'''....'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''......'''''.oWBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBO0c''''....''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''........'''''''',kBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBXkl,.'''....''''''''''''''''''''''''''''''''''''''''''''''''''''''........'''''''''''''lXBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWKd:''''......''''''''''''''''''''''''''''''''''''''''''''''''''...'''''''''''''''':xXBOBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBONOo;''''.......'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.,ckXBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOWXx:''''''.......''''''''''''''''''''''''''''''''''''''''''''''''.'',;::clx0WBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBXkl:,'''''''..........''''''''''.........'''''''''''''..',,;cldk0KXNNWBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWN0kdoc:,''''''............................'',;;:lodxkOKXNWBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBWNK0kdlc:;,,''''.......'',,;:cloodxxkO0KXNWWBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOWNXK0OOkkxxxxxxkkO0XNWWBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOB    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    BOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBO    //
//    *///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BOBOLOON is ERC1155Creator {
    constructor() ERC1155Creator("BOBO BALLOON", "BOBOLOON") {}
}