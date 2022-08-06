// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: outside the Tiandao
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//    Today, the first Emperor of Qin has just swept up the six states and unified the world. There are still lingering evils and rampant bandits in the six states. The outside world is not peaceful.                           //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//    Chen Qilin unarmed, a mortal, he decided to have nothing or go out less, if in the Tiandao building is relatively safe.                                                                                                     //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//    The Heavenly Way system told Chen Qilin that he would stay in Daqin for ten years and asked him to earn as many Heavenly Way points as possible. The more he earned, the more generous the reward would be when he left.    //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OTTD is ERC721Creator {
    constructor() ERC721Creator("outside the Tiandao", "OTTD") {}
}