// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Opepengs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    dHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHb          //
//    HHP%%#%%%%%%%%%%%%%%%%#%%%%%%%#%%VHH          //
//    HH%%%%%%%%%%#%v~~~~~~\%%%#%%%%%%%%HH          //
//    HH%%%%%#%%%%v'        ~~~~\%%%%%#%HH          //
//    HH%%#%%%%%%v'dHHb      a%%%#%%%%%%HH          //
//    HH%%%%%#%%v'dHHHA     :%%%%%%#%%%%HH          //
//    HH%%%#%%%v' VHHHHaadHHb:%#%%%%%%%%HH          //
//    HH%%%%%#v'   `VHHHHHHHHb:%%%%%#%%%HH          //
//    HH%#%%%v'      `VHHHHHHH:%%%#%%#%%HH          //
//    HH%%%%%'        dHHHHHHH:%%#%%%%%%HH          //
//    HH%%#%%        dHHHHHHHH:%%%%%%#%%HH          //
//    HH%%%%%       dHHHHHHHHH:%%#%%%%%%HH          //
//    HH#%%%%       VHHHHHHHHH:%%%%%#%%%HH          //
//    HH%%%%#   b    HHHHHHHHV:%%%#%%%%#HH          //
//    HH%%%%%   Hb   HHHHHHHV'%%%%%%%%%%HH          //
//    HH%%#%%   HH  dHHHHHHV'%%%#%%%%%%%HH          //
//    HH%#%%%   VHbdHHHHHHV'#%%%%%%%%#%%HH          //
//    HHb%%#%    VHHHHHHHV'%%%%%#%%#%%%%HH          //
//    HHHHHHHb    VHHHHHHH:%odHHHHHHbo%dHH          //
//    HHHHHHHHboodboooooodHHHHHHHHHHHHHHHH          //
//    HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH          //
//    VHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHV          //
//                                                  //
//                                  _               //
//                                 (_)              //
//     _ __   ___ _ __   __ _ _   _ _ _ __  ___     //
//    | '_ \ / _ \ '_ \ / _` | | | | | '_ \/ __|    //
//    | |_) |  __/ | | | (_| | |_| | | | | \__ \    //
//    | .__/ \___|_| |_|\__, |\__,_|_|_| |_|___/    //
//    | |                __/ |                      //
//    |_|               |___/                       //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract Opengs is ERC1155Creator {
    constructor() ERC1155Creator("Opepengs", "Opengs") {}
}