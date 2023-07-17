// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ODEN BALLOON
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                BBBBBBBBBBBB                                                                                                                    //
//                                                                           a%%%%AAAAAAAAAAAA%%%%a                                                                                                               //
//                                                                        .JJP9999]]]]]]]]]]]]9999PJJ.                                                                                                            //
//                                                                      ^|?ppy[]]]]]]]]]][[L!!!!L[ypp?|^                                                                                                          //
//                                                                      ]BMjj[[[]]]]]]]]]jj1''''!*LjjMB]                                                                                                          //
//                                                                      ]BMjj]]]]]]]]]]]]jjjjjjj_ .jjMB]                                                                                                          //
//                                                                    BBm4a]]]]]]]]]]]]]]jjjjjjjjj(  (jkBB                                                                                                        //
//                                                                    BBm4a]]]]]]]]]]]]]]]]]]]]][j(  (jkBB                                                                                                        //
//                                                                    BBm4a]]]]]]]]]]]]]]]]]]]]][jI!!IjkBB                                                                                                        //
//                                                                    BBm4a]]]]]]]]]]]]]]]]]]]]]][[]][[kBB                                                                                                        //
//                                                                    BBm4a]]]]]]]]]]]]]]]]]]]]]]]]]]]]kBB                                                                                                        //
//                                                                    BBm4a]]]]]]]]]]]]]]]]]]]]]]]]]]]]kBB                                                                                                        //
//                                                                    BBm4a]]]]]]]]]]]]]]]]]]]]]]]]]]]]kBB                                                                                                        //
//                                                                    ,,egRAAu]]]]]]]]]]]]]]]]]]]]]]]80y,,                                                                                                        //
//                                                                      ]BQ44u]]]]]]]]]]]]]]]]]]]]]]]MB]                                                                                                          //
//                                                                      !JYpp2eeee]]]]]]]]]]]]]]]]C99IJ!                                                                                                          //
//                                                                        `%%UkkkkCCn]]]]]]]]]AAAAa%%`                                                                                                            //
//                                                                           8BBBB44y]]]]]]]]]BBBB8                                                                                                               //
//                                                                                BBm444444mBB                                                                                                                    //
//                                                                                ,,egggggge,,                                                                                                                    //
//                                                                                JJ5pppppp5JJ                                                                                                                    //
//                                                                                BBRppppppRBB                                                                                                                    //
//                                                                                %%%%pBBp%%%%                                                                                                                    //
//                                                                                    'BB'                                                                                                                        //
//                                                                                    'BB'                                                                                                                        //
//                                                                                    'BB'                                                                                                                        //
//                                                                                    'BB'                                                                                                                        //
//                                                                                    'BB'                                                                                                                        //
//                                                                                    'BB'                                                                                                                        //
//                                                                                    'BB'                                                                                                                        //
//                                                                                       8B]                                                                                                                      //
//                                                                                       8B]      `%%%%*         a%%%%                                                                                            //
//                                                                                       8B]    !JlXXXXoJJ    .JJSXXXXJJ_                                                                                         //
//                                                                                       8B]    ]BgttttVGG||||?GGIttttBB!                                                                                         //
//                                                                                       8B]  ,,CR8tttttttRRRR8tttttttRR>,:                                                                                       //
//                                                                                       8B]  BB4tttttttttttttttttttttttpB8                                                                                       //
//                                                                                    'BB' !BBttttttttttttttttttttttttttttsBB'                                                                                    //
//                                                                                    'BB' !BBttttttttttttttttttttttttttttsBB'                                                                                    //
//                                                                                    'BB' !BBtttttttttVGGttaGkttkGattttttsBB'                                                                                    //
//                                                                                    'BB' !BBtt<1111TtVGGttaGkttkGatt1111vBB'                                                                                    //
//                                                                                    'BB' !BBii!^^^^<iLttCCItJCCJtTii^^^^!BB'                                                                                    //
//                                                                                    'BB' !BB^^^^^^^^^!ttBB4tsBBst/^^^^^^!BB'                                                                                    //
//                                                                                    'BB'    BBT^^^^LttttttpBgttttttt^^SB8                                                                                       //
//                                                                                     ,,Z%*  ,,sOOOORRRRRRRQBBRRRRRRROO/,:                                                                                       //
//                                                                                JJJJ?  +|?JJJJC2SBBS2222222222222222BB!                                                                                         //
//                                                                                BB8GP||. !BBPPJ/LBBS2222///////e2222BB!                                                                                         //
//                                                                                %%ACoRR",?BB////LBB0RgBB///////WBQRRBB!                                                                                         //
//                                                                                  ]BgttgBBBB////LBBst4BB///////WBpttBB!                                                                                         //
//                                                                                    'BBst4BB///////WB6///////////yBB                                                                                            //
//                                                                                     ,,mRgBB8888888BBN88888888888WBB                                                                                            //
//                                                                                       +|VBBXXXXXXXXXXXXXXXXXXXQB9||                                                                                            //
//                                                                                         _JJXXnttttSXXXXXXnttttgB]                                                                                              //
//                                                                                            BB4ttttgB0%%BB4ttttgB]                                                                                              //
//                                                                                            BB4ttttgB]  BB4ttttgB]                                                                                              //
//                                                                                              ]BBBB'      ]BBBB'                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ODEN is ERC1155Creator {
    constructor() ERC1155Creator("ODEN BALLOON", "ODEN") {}
}