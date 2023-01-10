// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: timmie does
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//             .. ........                                                                                                                                                                                        //
//                                                                                                  .  ..:,.......                                                                                                //
//                                                                                               .,.DMNZ$$ZDO$$$$ZM..........,. . .  .                                                                            //
//                                                                                               .DM$ZZZ$MZ$$$$$$$$$MN~=MMM$$$$MM=..                                                                              //
//                                                                                               M$$Z$$$$$$MZZ$Z888$$Z$ZOMMMMMMMMMM...                                                                            //
//                                                                                           .,.M$$$$$$$$$$$M8 ,    .$DZZZZ$Z$Z$$$$OO... .                                                                        //
//                                                                                          ,MMMZZ$$$$$$$$$M..       OMMM7D$8MMM$ZZZ$M....                                                                        //
//                                                                                       ..:M$$$$$$$$$$$$$Z$MI......MMM8,MM$$D$MN8OMMZ$M...                                                                       //
//                                                                                       ..M8$ZZ$$$$$$$$$$ZZ$NM.....MMMMMM M:..  .. MMMMNO .                                                                      //
//                                                                                       .MMZZ$$$$$$$$$$$$$$$$$MMM~.IMMMMMD..... . MMNMNMM                                                                        //
//                                                                                       MM$$$$$$$$$$$$$$$$$$$$$$$Z$$$$$$ZDM.. ,...MM8MMMDM. .                                                                    //
//                                                                                       MD$Z$$$$$$$$$$$$$$$Z$$ZZ$ZZZZZ$Z$$$OMMN=..MMMMMM$M. .                                                                    //
//                                                                                      MM7ZZ$$$$$$$$$$$$$$M77$OMMMMN88OZ$$$Z$$Z$Z$$ZZZ8O... .                                                                    //
//                                                                                   ..8M$$$$$$$$$$$$$$$ZZZ8O$ZMMZ$$$$$$$$$$$$$ZMMM$$$M...                                                                        //
//                                                                                   .,MMZ$$$$$$$$$$$$$$$8$Z$NO$$$7Z8OODNMMMMMNO$$7$$$M...                                                                        //
//                                                                               .....MM$Z$$$$$$$$$$$$ZZZMDZZ$ZZMM87$7$$$$$$7$$7$$$OM$M ..                                                                        //
//                                                                                . :MMZ$$$$$$$Z$ZZ$$$$$$$$Z$$$$$ZZZ$$ONMMMMMMMMMMD$$M.. .                                                                        //
//                                                                                .ZMZZZ$$$$$$$$$MDZ$$Z$$$$$$Z$$$$ZZZZ$ZZZZ$Z$$ZZ$Z$M.....                                                                        //
//                                                                                IM$Z$$$$$$$ZZOMMZZ$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$M..                                                                            //
//                                                                              ..M$$$$$$$$Z$$MM$Z$$$$$$$$$$$Z$$$$$$$$$$$$$$$$$$$$M...                                                                            //
//                                                                              .DM$$$$$$$ZZMM8ZZ$Z$$$$Z$$ZZM$ZZ$Z$$$ZZZ$Z$$$$$$$$M...                                                                            //
//                                                                               MD$$$$$$$$MMMMMMMO$$$ZZZDMM$MZZZ$Z$ZM$ZZ$$$$$$ZZ$M~..                                                                            //
//                                                                              .7M$$$$$$$$ZZ$$$$ZMMMMMMMMZ$OZMDZ$$$Z$ZM8$$$$$$$$NM+..                                                                            //
//                                                                              ..MOZZ$$$$$$$$$$$$$$ZZZZZ$$Z$MMMZ$$$$$$$$NMMMMMMMMM.......                                                                        //
//                                                                               .,MO$$$Z$ZZZZZZ$Z$$$Z$$$ZZ$DMMM$Z$$$$$$Z$$$$$$Z$8M. ~D~.. .                                                                      //
//                                                                               ..MNMMMMMMMMMDDD88DDDDMMM$Z$$ZMZZ$$$$$$$$$$$$$$$MMNM$Z$OM,...                                                                    //
//                                                                               .+M$$ZZ$$$$$Z$Z$$$Z$$Z$ZMMMMMM$ZZ$$$$$$$$$$$$Z$MMNZZ$$NDMN=..                                                                    //
//                                                                                MMZZ$$ZZ$$$$$$$$$$$$$$ZZ$$Z$ZZ$$$$$$$$$$$$$$$NMMZ$$$OM$ZZM..                                                                    //
//                                                                              .NM$Z$ZZZZ$$$$$$$$$$$$$$ZZ$$$$ZZ$$$$$$$$$$$$$$ZMMZ$$$$$DZZ$M..                                                                    //
//                                                                              .MM$Z$ZZ$$$$$$$$$$$$ZZ$$$$$$$$$$$$ZZZZ$$ZZ$$$$MMZZZ$$$Z$N$8: .                                                                    //
//                                                                              MM$Z$$ZZ$$$$$$$$$$$$ZZ$$$$$$$$$$ZZZZZZ$$ZZ$$$ZMMZ$8I.NMNM~....                                                                    //
//                                                                           .,MM7$$$$$$$$$$$$$$$$ZZZZZZ$Z$$$$$$Z$Z$$$ZZ$$$Z$MDD$....    .                                                                        //
//                                                                           .MM8$$$$$$$$$$$$$$$$$$$$$Z88Z$$$$$$$$$Z$$$$$$$$MM....                                                                                //
//                                                                           .MM$Z$$$$$$$$$$$$$$$$$$$$Z$MNZZ$$$Z$MOZZ$$$$Z$MM.                                                                                    //
//                                                                           .MM$Z$$$$$$$$$$$$$$$$$$$$$ZZMMZ$Z$$$MMZZ$$$$ZMM..                                                                                    //
//                                                                           .MM$$$$$$$$$$$$$$$$$$$$$$$$$Z$MMZ$$ZZZZ$$ZOMM....                                                                                    //
//                                                                            .MM$ZZ$$$$$$$$$$$$$$$$$$$$$$ZZNMM$ZZZZZZMM,.                                                                                        //
//                                                                            ..MMNZ$ZZZZZ$$$$$$$$$$$$$$$$ZZZ$MMMNNMMM+. .                                                                                        //
//                                                                            ....MMMMDN$ZZZ$Z$$$$$$$$$$$$$$$$$ZOMMM....                                                                                          //
//                                                                            .....ZM78MMM8ZZ$$$$$$$$$$$$$$$$$ZZZZZM..                                                                                            //
//                                                                      ..8MMMMMMMNZ$$$ZZ$MMN$$$$$$$$$$$$$$$$$$$$OZMM.                                                                                            //
//                                                                      ,MM$$ZZZ$$$$$$ZZ$$$ZMMZZ$$$$$$ZZ$$ZZ$$$$NMMZM:                                                                                            //
//                                                                      7M$Z$$$$$$$$$$$$$$ZZZZMM$Z$$$$ZZ$$Z$$$Z$MM.MM,                                                                                            //
//                                                                      ~MZZ$$$$$$$$$$$$$$$$$$Z8M$$$$$$$$$Z$$$Z$MN....                                                                                            //
//                                                                      .M$Z$Z$$$$ZZZZZZ$$$$$$ZZMMO$Z$$$$$$$$$$MM.                                                                                                //
//                                                                       M$Z$Z$$MMMMMMMMMMMMMMM+.,MMZZ$$$$$$Z$MM8.                                                                                                //
//                                                                      .M8Z$$$$MN.  . ..,, .    .$MZZ$$$$$Z$MMM..                                                                                                //
//                                                                       MMZ$$$$MO               ..M$$$$$$$$8MM                                                                                                   //
//                                                                       .M$$$$$M=               ..MZ$$$$$$$MM..                                                                                                  //
//                                                                        7M$Z$OM.               .IMZ$$$$$ZMMMMMMM:...                                                                                            //
//                                                                        .$MMOM8.               .MMZZ$$$$Z$ZZ$$$8MMM:                                                                                            //
//                                                                           ..                  .MMZ$$$Z$Z$$$$$$$$$ZM8.                                                                                          //
//                                                                          ...                  .MM$$$$ZOO$$$Z$$$$ZZ$MD .                                                                                        //
//                                                                                               .=MMMMMMMMMMMMMMMMMMMD ..                                                                                        //
//                                                                                                      . .  . .. .. .                                                                                            //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract slug is ERC721Creator {
    constructor() ERC721Creator("timmie does", "slug") {}
}