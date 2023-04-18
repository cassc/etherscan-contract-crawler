// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: clubNICHE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//    ⁣⠀⠀⠀ (\/)                       //
//    ⠀⠀⠀ (•ㅅ•)      are you a man    //
//    ＿ノヽ ノ＼＿                         //
//    /  / ⌒Ｙ⌒ Ｙ  ヽ     or woman      //
//    ( 　(三ヽ人　 /　  |                  //
//    |　ﾉ⌒＼ ￣￣ヽ   ノ                   //
//    ヽ＿＿＿＞､＿_／                       //
//    ⠀⠀ ｜( 王 ﾉ〈  ⠀ (\/)              //
//    ⠀⠀/ﾐ`ー―彡\   ⠀ (•ㅅ•)             //
//    ⠀⠀/ ╰    ╯ \⠀⠀  / \>            //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract MOW is ERC1155Creator {
    constructor() ERC1155Creator("clubNICHE", "MOW") {}
}