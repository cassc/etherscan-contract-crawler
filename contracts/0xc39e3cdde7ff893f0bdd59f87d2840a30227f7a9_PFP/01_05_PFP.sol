// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WY_mask
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    #WEB3痴迷者  #暴富幻想家                   //
//    #一位靠实力吃饭的颜值博主                      //
//    乐于分享，相信劳有所得，天降甘霖，随风而行，惟器所盛         //
//    空投表单见这里：http://link3.to/wy_mask    //
//    别回头看，身后万盏灯火，都不是归处...               //
//                                       //
//                                       //
///////////////////////////////////////////


contract PFP is ERC721Creator {
    constructor() ERC721Creator("WY_mask", "PFP") {}
}