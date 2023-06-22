// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jabbers Emporium Of The Weird And Fantastic
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                :::!~!!!!!:.                        //
//                      .xUHWH!! !!?M88WHX:.          //
//                    .X*#[email protected]$!!  !X!M$$$$$$WWx:.      //
//                   :!!!!!!?H! :!$!$$$$$$$$$$8X:     //
//                  !!~  ~:~!! :~!$!#$$$$$$$$$$8X:    //
//                 :!~::!H!<   ~.U$X!?R$$$$$$$$MM!    //
//                 ~!~!!!!~~ .:XW$$$U!!?$$$$$$RMM!    //
//                   !:~~~ .:!M"T#$$$$WX??#MRRMMM!    //
//                   ~?WuxiW*`   `"#$$$$8!!!!??!!!    //
//                 :X- M$$$$       `"T#$T~!8$WUXU~    //
//                :%`  ~#$$$m:        ~!~ ?$$$$$$     //
//              :!`.-   ~T$$$$8xx.  .xWW- ~""##*"     //
//    .....   -~~:<` !    ~?T#[email protected]@[email protected]*?$$      /`      //
//    [email protected]@M!!! .!~~ !!     .:XUW$W!~ `"~:    :        //
//    #"~~`.:x%`!!  !H:   !WM$$$$Ti.: .!WUn+!`        //
//    :::~:!!`:X~ .: ?H.!u "$$$B$$$!W:U!T$$M~         //
//    .~~   :[email protected]!.-~   [email protected]("*$$$W$TH$! `            //
//    Wi.~!X$?!-~    : ?$$$B$Wu("**$RM!               //
//    [email protected]~~ !     :   ~$$$$$B$$en:``                //
//    [email protected]~    :     ~"##*$$$$M~                  //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract JE is ERC721Creator {
    constructor() ERC721Creator("Jabbers Emporium Of The Weird And Fantastic", "JE") {}
}